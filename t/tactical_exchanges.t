#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::FailWarnings;

use Finance::Exchange;
use Finance::Calendar;

# Create a basic calendar for testing
my $calendar = {
    holidays     => {},
    early_closes => {},
    late_opens   => {},
};

my $tc = Finance::Calendar->new(calendar => $calendar);
my ($TACTICAL_FOREX_EURUSD, $TACTICAL_FOREX_GBPUSD, $TACTICAL_FOREX_USDJPY, $TACTICAL_METALS, $TACTICAL_CRYPTO) =
    map { Finance::Exchange->create_exchange($_) } qw(TACTICAL_FOREX_EURUSD TACTICAL_FOREX_GBPUSD TACTICAL_FOREX_USDJPY TACTICAL_METALS TACTICAL_CRYPTO);

subtest 'tactical_trading_days' => sub {
    # Test sun_thru_fri pattern for TACTICAL forex exchanges
    my $sunday   = Date::Utility->new('2023-06-11');    # Sunday
    my $monday   = Date::Utility->new('2023-06-12');    # Monday
    my $friday   = Date::Utility->new('2023-06-16');    # Friday
    my $saturday = Date::Utility->new('2023-06-17');    # Saturday

    # tactical Forex exchanges should trade Sunday through Friday
    ok $tc->trades_on($TACTICAL_FOREX_EURUSD,  $sunday),   'TACTICAL_FOREX_EURUSD trades on Sunday';
    ok $tc->trades_on($TACTICAL_FOREX_EURUSD,  $monday),   'TACTICAL_FOREX_EURUSD trades on Monday';
    ok $tc->trades_on($TACTICAL_FOREX_EURUSD,  $friday),   'TACTICAL_FOREX_EURUSD trades on Friday';
    ok !$tc->trades_on($TACTICAL_FOREX_EURUSD, $saturday), 'TACTICAL_FOREX_EURUSD does not trade on Saturday';

    ok $tc->trades_on($TACTICAL_FOREX_GBPUSD,  $sunday),   'TACTICAL_FOREX_GBPUSD trades on Sunday';
    ok !$tc->trades_on($TACTICAL_FOREX_GBPUSD, $saturday), 'TACTICAL_FOREX_GBPUSD does not trade on Saturday';

    ok $tc->trades_on($TACTICAL_FOREX_USDJPY,  $sunday),   'TACTICAL_FOREX_USDJPY trades on Sunday';
    ok !$tc->trades_on($TACTICAL_FOREX_USDJPY, $saturday), 'TACTICAL_FOREX_USDJPY does not trade on Saturday';

    ok $tc->trades_on($TACTICAL_METALS,  $sunday),   'TACTICAL_METALS trades on Sunday';
    ok !$tc->trades_on($TACTICAL_METALS, $saturday), 'TACTICAL_METALS does not trade on Saturday';

    # TACTICAL_CRYPTO should trade every day
    ok $tc->trades_on($TACTICAL_CRYPTO, $sunday),   'TACTICAL_CRYPTO trades on Sunday';
    ok $tc->trades_on($TACTICAL_CRYPTO, $saturday), 'TACTICAL_CRYPTO trades on Saturday';
};

subtest 'tactical_trading_hours_standard' => sub {
    # Test during standard time (non-DST) - using February dates
    my $sunday   = Date::Utility->new('2023-02-12');    # Sunday in standard time
    my $monday   = Date::Utility->new('2023-02-13');    # Monday in standard time
    my $friday   = Date::Utility->new('2023-02-17');    # Friday in standard time
    my $saturday = Date::Utility->new('2023-02-18');    # Saturday in standard time

    # Verify we're in standard time
    ok !$tc->is_in_dst_at($TACTICAL_FOREX_EURUSD, $sunday->epoch), 'February Sunday is in standard time';
    ok !$tc->is_in_dst_at($TACTICAL_FOREX_EURUSD, $friday->epoch), 'February Friday is in standard time';

    # Test TACTICAL_FOREX_EURUSD standard time hours
    my $sunday_open = $tc->opening_on($TACTICAL_FOREX_EURUSD, $sunday);
    is $sunday_open->time_hhmmss, '22:35:00', 'TACTICAL_FOREX_EURUSD opens at 22:35:00 on Sunday (standard time)';

    # Monday should open at 00:00 (0s)
    my $monday_open = $tc->opening_on($TACTICAL_FOREX_EURUSD, $monday);
    is $monday_open->time_hhmmss, '00:00:00', 'TACTICAL_FOREX_EURUSD opens at 00:00:00 on Monday (standard time)';

    # Monday should close at 23:59:59 (23h59m59s)
    my $monday_close = $tc->closing_on($TACTICAL_FOREX_EURUSD, $monday);
    is $monday_close->time_hhmmss, '23:59:59', 'TACTICAL_FOREX_EURUSD closes at 23:59:59 on Monday (standard time)';

    # Friday should close early at 21:55 (21h55m)
    my $friday_close = $tc->closing_on($TACTICAL_FOREX_EURUSD, $friday);
    is $friday_close->time_hhmmss, '21:55:00', 'TACTICAL_FOREX_EURUSD closes at 21:55:00 on Friday (standard time)';

    # Test other tactical forex exchanges have same pattern
    is $tc->opening_on($TACTICAL_FOREX_GBPUSD, $sunday)->time_hhmmss, '22:35:00', 'TACTICAL_FOREX_GBPUSD Sunday opens at 22:35:00 (standard)';
    is $tc->closing_on($TACTICAL_FOREX_GBPUSD, $friday)->time_hhmmss, '21:55:00', 'TACTICAL_FOREX_GBPUSD Friday closes at 21:55:00 (standard)';

    # TACTICAL_FOREX_USDJPY starts on 23:05 on Sunday
    is $tc->opening_on($TACTICAL_FOREX_USDJPY, $sunday)->time_hhmmss, '23:05:00', 'TACTICAL_FOREX_USDJPY Sunday opens at 23:05:00 (standard)';
    is $tc->closing_on($TACTICAL_FOREX_USDJPY, $friday)->time_hhmmss, '21:55:00', 'TACTICAL_FOREX_USDJPY Friday closes at 21:55:00 (standard)';

    # TACTICAL_METALS has different Friday close (20:45)
    is $tc->opening_on($TACTICAL_METALS, $sunday)->time_hhmmss, '23:05:00', 'TACTICAL_METALS Sunday opens at 23:05:00 (standard)';
    is $tc->closing_on($TACTICAL_METALS, $friday)->time_hhmmss, '20:45:00', 'TACTICAL_METALS Friday closes at 20:45:00 (standard)';

    # TACTICAL_CRYPTO should be 24/7
    is $tc->opening_on($TACTICAL_CRYPTO, $sunday)->time_hhmmss,   '00:00:00', 'TACTICAL_CRYPTO opens at 00:00:00 on Sunday (24/7)';
    is $tc->closing_on($TACTICAL_CRYPTO, $sunday)->time_hhmmss,   '23:59:59', 'TACTICAL_CRYPTO closes at 23:59:59 on Sunday (24/7)';
    is $tc->opening_on($TACTICAL_CRYPTO, $saturday)->time_hhmmss, '00:00:00', 'TACTICAL_CRYPTO opens at 00:00:00 on Saturday (24/7)';
    is $tc->closing_on($TACTICAL_CRYPTO, $saturday)->time_hhmmss, '23:59:59', 'TACTICAL_CRYPTO closes at 23:59:59 on Saturday (24/7)';
};

subtest 'tactical_trading_hours_dst' => sub {
    # Test during DST - using July dates
    my $sunday = Date::Utility->new('2023-07-09');    # Sunday in DST
    my $friday = Date::Utility->new('2023-07-14');    # Friday in DST

    # Verify we're in DST
    ok $tc->is_in_dst_at($TACTICAL_FOREX_EURUSD, $sunday->epoch), 'July Sunday is in DST';
    ok $tc->is_in_dst_at($TACTICAL_FOREX_EURUSD, $friday->epoch), 'July Friday is in DST';

    # Test TACTICAL_FOREX_EURUSD DST hours
    my $sunday_open = $tc->opening_on($TACTICAL_FOREX_EURUSD, $sunday);
    is $sunday_open->time_hhmmss, '21:35:00', 'TACTICAL_FOREX_EURUSD opens at 21:35:00 on Sunday (DST)';

    my $friday_close = $tc->closing_on($TACTICAL_FOREX_EURUSD, $friday);
    is $friday_close->time_hhmmss, '20:55:00', 'TACTICAL_FOREX_EURUSD closes at 20:55:00 on Friday (DST)';

    # Test other tactical forex exchanges
    is $tc->opening_on($TACTICAL_FOREX_GBPUSD, $sunday)->time_hhmmss, '21:35:00', 'TACTICAL_FOREX_GBPUSD Sunday opens at 21:35:00 (DST)';
    is $tc->closing_on($TACTICAL_FOREX_GBPUSD, $friday)->time_hhmmss, '20:55:00', 'TACTICAL_FOREX_GBPUSD Friday closes at 20:55:00 (DST)';

    # TACTICAL_FOREX_USDJPY
    is $tc->opening_on($TACTICAL_FOREX_USDJPY, $sunday)->time_hhmmss, '22:05:00', 'TACTICAL_FOREX_USDJPY Sunday opens at 22:05:00 (DST)';
    is $tc->closing_on($TACTICAL_FOREX_USDJPY, $friday)->time_hhmmss, '20:55:00', 'TACTICAL_FOREX_USDJPY Friday closes at 20:55:00 (DST)';

    # TACTICAL_METALS has different Friday close (19:45 in DST)
    is $tc->opening_on($TACTICAL_METALS, $sunday)->time_hhmmss, '22:05:00', 'TACTICAL_METALS Sunday opens at 22:05:00 (DST)';
    is $tc->closing_on($TACTICAL_METALS, $friday)->time_hhmmss, '19:45:00', 'TACTICAL_METALS Friday closes at 19:45:00 (DST)';
};

subtest 'tactical_friday_close_adjustments' => sub {
    # Test regularly_adjusts_trading_hours_on method
    my $monday     = Date::Utility->new('2023-02-13');    # Monday
    my $friday     = Date::Utility->new('2023-02-17');    # Friday (standard time)
    my $friday_dst = Date::Utility->new('2023-07-14');    # Friday (DST)

    # Monday should not have adjustments
    ok !$tc->regularly_adjusts_trading_hours_on($TACTICAL_FOREX_EURUSD, $monday), 'TACTICAL_FOREX_EURUSD does not adjust hours on Monday';

    # Friday should have adjustments (standard time)
    my $friday_changes = $tc->regularly_adjusts_trading_hours_on($TACTICAL_FOREX_EURUSD, $friday);
    ok $friday_changes,                       'TACTICAL_FOREX_EURUSD adjusts hours on Friday';
    ok exists $friday_changes->{daily_close}, 'Friday adjustment includes daily_close';
    is $friday_changes->{daily_close}->{to}->as_concise_string, '21h55m',  'Friday close adjusted to 21h55m (standard)';
    is $friday_changes->{daily_close}->{rule},                  'Fridays', 'Adjustment rule is "Fridays" (standard)';

    # Friday should have adjustments (DST)
    my $friday_dst_changes = $tc->regularly_adjusts_trading_hours_on($TACTICAL_FOREX_EURUSD, $friday_dst);
    ok $friday_dst_changes, 'TACTICAL_FOREX_EURUSD adjusts hours on Friday (DST)';
    is $friday_dst_changes->{daily_close}->{to}->as_concise_string, '20h55m',        'Friday close adjusted to 20h55m (DST)';
    is $friday_dst_changes->{daily_close}->{rule},                  'Fridays (DST)', 'Adjustment rule is "Fridays (DST)"';

    # Test closes_early_on method
    ok $tc->closes_early_on($TACTICAL_FOREX_EURUSD,  $friday), 'TACTICAL_FOREX_EURUSD closes early on Friday';
    ok !$tc->closes_early_on($TACTICAL_FOREX_EURUSD, $monday), 'TACTICAL_FOREX_EURUSD does not close early on Monday';

    # Test different exchanges have different Friday close times
    my $metal_friday_changes = $tc->regularly_adjusts_trading_hours_on($TACTICAL_METALS, $friday);
    is $metal_friday_changes->{daily_close}->{to}->as_concise_string, '20h45m', 'TACTICAL_METALS Friday close is 20h45m (standard)';

    my $metal_friday_dst_changes = $tc->regularly_adjusts_trading_hours_on($TACTICAL_METALS, $friday_dst);
    is $metal_friday_dst_changes->{daily_close}->{to}->as_concise_string, '19h45m', 'TACTICAL_METALS Friday close is 19h45m (DST)';

    # Test other tactical forex exchanges
    my $gbp_friday_changes = $tc->regularly_adjusts_trading_hours_on($TACTICAL_FOREX_GBPUSD, $friday);
    is $gbp_friday_changes->{daily_close}->{to}->as_concise_string, '21h55m', 'TACTICAL_FOREX_GBPUSD Friday close is 21h55m (standard)';

    my $jpy_friday_changes = $tc->regularly_adjusts_trading_hours_on($TACTICAL_FOREX_USDJPY, $friday);
    is $jpy_friday_changes->{daily_close}->{to}->as_concise_string, '21h55m', 'TACTICAL_FOREX_USDJPY Friday close is 21h55m (standard)';
};

done_testing();
