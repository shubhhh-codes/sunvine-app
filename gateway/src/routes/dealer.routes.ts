import { Hono } from 'hono';
import { Env, DealerProfile } from '../types.js';
import { errorResponse } from '../utils/error.js';
import { getSupabase } from '../utils/supabase.js';
import { requireDealer } from '../middleware/auth.js';

export const dealerRoutes = new Hono<{ Bindings: Env; Variables: { dealerId: string } }>();

dealerRoutes.use('*', requireDealer);

dealerRoutes.get('/v1/me', async (c) => {
  const dealerId = c.get('dealerId');
  const supabase = getSupabase(c.env);

  const { data: dealer, error } = await supabase
    .from('dealer_accounts')
    .select('id, dealer_code, firm_name, contact_person, mobile_number, email, status, city, state, discom, tier, max_margin_cap_per_kw, assigned_staff_id, assigned_staff_name, pricing_config')
    .eq('id', dealerId)
    .maybeSingle();

  if (error || !dealer) {
    const err = errorResponse('INVALID_CREDENTIALS', 'Dealer account not found.', 404);
    return c.json(err.body, err.status);
  }

  if (dealer.status === 'suspended' || dealer.status === 'inactive') {
    const err = errorResponse('ACCOUNT_SUSPENDED', 'Account suspended, contact Sunvine support.', 403);
    return c.json(err.body, err.status);
  }

  const isDirect = dealer.assigned_staff_id === 'STF-DIRECT';
  const userProfile: DealerProfile = {
    id: dealer.id,
    dealerCode: dealer.dealer_code,
    role: 'dealer',
    mobile: dealer.mobile_number,
    firmName: dealer.firm_name,
    contactPerson: dealer.contact_person,
    city: dealer.city,
    state: dealer.state,
    discom: dealer.discom,
    tier: dealer.tier,
    maxMarginCapPerKw: Number(dealer.max_margin_cap_per_kw),
    assignedStaffId: dealer.assigned_staff_id || 'STF-DIRECT',
    assignedStaffName: dealer.assigned_staff_name || (isDirect ? 'Direct to Company (HQ Desk)' : 'Sunvine Sales Staff'),
    category: dealer.pricing_config?.category || 'Margin Based',
    pricingConfig: dealer.pricing_config || {},
  };

  return c.json({ success: true, user: userProfile });
});

dealerRoutes.get('/v1/catalog/bootstrap', async (c) => {
  const supabase = getSupabase(c.env);

  try {
    const [
      settingsRes,
      modulesRes,
      invertersRes,
      presetsRes,
      tierMarginsRes,
      benchmarksRes,
      bosRes,
      banksRes,
    ] = await Promise.all([
      supabase.from('system_settings').select('id, governance_settings, statutory_taxes, company_profile, bank_details').eq('id', 'global_settings').maybeSingle(),
      supabase.from('solar_modules').select('id, brand, model, wattage, cell_tech, efficiency, rate_per_wp_inr, warranty, dimensions').order('created_at', { ascending: false }),
      supabase.from('solar_inverters').select('id, brand, model, capacity_kw, phase, base_price_inr, warranty').order('created_at', { ascending: false }),
      supabase.from('pricing_presets').select('id, base_rate_per_kw, subsidy_cap, min_margin_per_kw, enforce_min_margin').eq('id', 'global_default').maybeSingle(),
      supabase.from('dealer_custom_pricing').select('id, tier, tier_id, max_margin_cap_per_kw, min_margin_per_kw, discount_on_bom_pct').order('tier', { ascending: true }),
      supabase.from('inverter_benchmark_matrix').select('id, capacity_kw, phase, brand, benchmark_price_inr').order('capacity_kw', { ascending: true }),
      supabase.from('bos_pricing_matrix').select('capacity_slab, panel_brand, bos_price_per_wp, gst_rate').order('capacity_slab', { ascending: true }),
      supabase.from('solar_banks').select('id, bank_name, interest_rate, max_tenure_years, processing_fee').order('bank_name', { ascending: true }),
    ]);

    return c.json({
      success: true,
      settings: settingsRes.data || {},
      catalog: {
        hardware: {
          modules: modulesRes.data || [],
          inverters: invertersRes.data || [],
        },
        presets: presetsRes.data || {},
        tierMargins: tierMarginsRes.data || [],
        inverterBenchmarks: benchmarksRes.data || [],
        bosMatrix: bosRes.data || [],
        solarBanks: banksRes.data || [],
      },
    });
  } catch (err: any) {
    const resp = errorResponse('ORIGIN_ERROR', 'Failed to retrieve catalog data: ' + err.message, 500);
    return c.json(resp.body, resp.status);
  }
});

dealerRoutes.get('/v1/quotations', async (c) => {
  const dealerId = c.get('dealerId');
  const limit = Math.min(100, Math.max(1, parseInt(c.req.query('limit') || '50', 10)));
  const offset = Math.max(0, parseInt(c.req.query('offset') || '0', 10));

  const supabase = getSupabase(c.env);
  const selectColumns = 'id, dealer_id, dealer_code, dealer_name, customer_name, customer_phone, customer_city, customer_state, system_capacity_kw, panel_type, inverter_type, structure_type, total_amount, subsidy_amount, net_payable, annual_generation_kwh, status, share_token, request_id, share_expires_at, quote_payload, created_at, updated_at';

  const { data, count, error } = await supabase
    .from('quotations')
    .select(selectColumns, { count: 'exact' })
    .eq('dealer_id', dealerId)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    const err = errorResponse('ORIGIN_ERROR', 'Failed to fetch quotations: ' + error.message, 500);
    return c.json(err.body, err.status);
  }

  return c.json({
    success: true,
    quotations: data || [],
    total: count !== null && count !== undefined ? count : (data || []).length,
    limit,
    offset,
  });
});

dealerRoutes.get('/v1/customer-files', async (c) => {
  const dealerId = c.get('dealerId');
  const limit = Math.min(100, Math.max(1, parseInt(c.req.query('limit') || '50', 10)));
  const offset = Math.max(0, parseInt(c.req.query('offset') || '0', 10));

  const supabase = getSupabase(c.env);
  const selectColumns = 'id, customer_name, phone, address, city, discom, consumer_no, sanctioned_load_kw, solar_system_kw, roof_type, source_type, dealer_id, dealer_name, staff_id, staff_name, finance_type, loan_bank, stage, status, documents, timeline, cancellation_reason, cancelled_at, cancelled_by, is_verified, verified_at, verified_by, is_deleted, created_at, updated_at';

  const { data, count, error } = await supabase
    .from('customer_files')
    .select(selectColumns, { count: 'exact' })
    .eq('dealer_id', dealerId)
    .not('is_deleted', 'is', true)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    const err = errorResponse('ORIGIN_ERROR', 'Failed to fetch customer files: ' + error.message, 500);
    return c.json(err.body, err.status);
  }

  const formatted = (data || []).map((f: any) => ({
    id: f.id,
    customerName: f.customer_name,
    phone: f.phone,
    address: f.address,
    city: f.city,
    discom: f.discom,
    consumerNo: f.consumer_no,
    sanctionedLoadKw: Number(f.sanctioned_load_kw) || 0,
    solarSystemKw: Number(f.solar_system_kw) || 0,
    roofType: f.roof_type,
    sourceType: f.source_type,
    dealerId: f.dealer_id,
    dealerName: f.dealer_name,
    stage: f.stage || 'LEAD_SOURCED',
    status: f.status || 'Sourced',
    isVerified: Boolean(f.is_verified),
    createdAt: f.created_at,
  }));

  return c.json({
    success: true,
    files: formatted,
    total: count !== null && count !== undefined ? count : formatted.length,
    limit,
    offset,
  });
});

dealerRoutes.get('/v1/ledger', async (c) => {
  const dealerId = c.get('dealerId');
  const supabase = getSupabase(c.env);

  const selectColumns = 'id, voucher_no, dealer_id, dealer_code, dealer_name, customer_file_id, customer_name, entry_date, entry_type, category, amount, payment_mode, reference_no, narration, proof_url, created_by, created_at';

  const { data, error } = await supabase
    .from('dealer_ledger_entries')
    .select(selectColumns)
    .eq('dealer_id', dealerId)
    .order('entry_date', { ascending: true })
    .order('created_at', { ascending: true });

  if (error) {
    const err = errorResponse('ORIGIN_ERROR', 'Failed to fetch financial ledger: ' + error.message, 500);
    return c.json(err.body, err.status);
  }

  let runningBalance = 0;
  let totalDebit = 0;
  let totalCredit = 0;

  const entriesWithBalance = (data || []).map((entry: any) => {
    const amt = Number(entry.amount) || 0;
    if (entry.entry_type === 'DEBIT') {
      runningBalance += amt;
      totalDebit += amt;
    } else {
      runningBalance -= amt;
      totalCredit += amt;
    }
    return { ...entry, running_balance: runningBalance };
  });

  return c.json({
    success: true,
    entries: entriesWithBalance.reverse(), // newest first
    summary: {
      totalDebit,
      totalCredit,
      netBalance: totalDebit - totalCredit,
      totalEntries: entriesWithBalance.length,
    },
  });
});
