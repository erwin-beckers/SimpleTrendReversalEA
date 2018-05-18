# Donations are welcome !!

Like what you see ? Feel free to donate to support further developments..


[![Donate with Bitcoin](https://en.cryptobadges.io/badge/small/3QcDYZEVwNZ9V7T9rrVz82JgPZf2e6prTH)](https://en.cryptobadges.io/donate/3QcDYZEVwNZ9V7T9rrVz82JgPZf2e6prTH)

[![Donate with Litecoin](https://en.cryptobadges.io/badge/small/LawBvKHL77gaVMQ3DM7Bk8KJdZDq43r6PL)](https://en.cryptobadges.io/donate/LawBvKHL77gaVMQ3DM7Bk8KJdZDq43r6PL)

[![Donate with Ethereum](https://en.cryptobadges.io/badge/small/0xe7350b2a0fe5bfa6c491e15d1b00b8a111350af9)](https://en.cryptobadges.io/donate/0xe7350b2a0fe5bfa6c491e15d1b00b8a111350af9)


# SimpleTrendReversalEA
MT4 EA for the simple trend reversal strategy invented by mrdfx

Read more about the strategy here:

www.forexfactory.com/showthread.php?t=713593

Ideas:
- set SL x pips below/above S&R line
- Close part of position when price encounters next SR line then trail the remaining position 
- calculate RR based on SL and next S&R line




# Version history:

1.23
- fixed re-entry code
- added SignalInvalidAfterHours setting, which will prevent the EA from opening trades when the signal is  too old
- added SignalInvalidAfterPips setting, which will prevent the EA from opening trades when price moved to far from the original signal

1.21
- small bugfix

1.18.4
- added (optional) S&R filter where EA will only open trades which are appearing at S&R levels

1.18.3
- code refactoring
- fixed trade panel showed wrong nr of pips for today's profit
- hopefully fixed bug where EA closed after changing settings

1.18.2
- fixed bug when no pairs where found
- click on pair label in open orders now opens the chart for that pair
- fixed issue where ea kept trying to close an order which was already closed

1.18.1
- fixed bug invalid pointer access in 'CPair.mqh' (537,17)
- which happened when EA was evaluating if it was allowed to do a re-entry or not

1.18
- fixed EA showed wrong nr of pips for open orders
- fixed EA closed orders too late
- added option to show only pairs with at least x valid signals
- revamped gui
- added MaxSpreadInPips: EA wont open/close trades if spread > MaxSpreadInPips
- added MaxOpenTrades: EA wont open more then MaxOpenTrades trades simultanously
- added AllowReEntries: EA won't open re-entries on same signal when enabled
- rewrote money management module to support : fixed lotsize, fixed amount dollar or percentage of equity
- code refactored

1.17
- fixed point error in zigzag
- show version, timeframe in lastupdate line
- show total pips in ea stats panel
- show SL in pips and order type on open trades
- fixed ea giving same alert multiple times

1.16
- fixed bug that mbfx showed invalid overbought signal
- fixed trendline z
- added an (optional) sma200 trendline filter 
- You can now click on sa currency pair to open the chart for this pair


1.15
- added minsBetween2TradesOnSamePair . this setting specifies the nr or minutes before a new trade opened on the same pair
- added missing  pairs to default settings
- changed default for mbfxcandles to 10
- added email alerts
- changed sma15 rule. price of previous candle should just now be above/under sma15 to be considered a valid signal

1.14
- fixed issue that EA did not show valid signal due to MBFX

1.13
- fixed: After a restart the EA set the stoploss at OrderSL instead of the tip of the zigzagarrow
- EA now closes the order if another arrow appears
- EA now shows open orders

1.12
- EA now shows last update/refresh time so we can check that EA is still refreshing the dashboard

1.11
- fixed news description overlapping with trade panel

1.10
- fixed ea did not open when there was upcoming news for other pairs
- new pair filter allows you to specify which pairs you want to trade

1.09
- fixed error 4107 invalid price xxx for OrderSend function
- fixed error 4107 invalid price xxx for OrderClose function

1.08
- changed default for trendline and zigzag/mbfx candles
- EA send same alert every minute
- made MA15 more restrict  
- use the Point & Digit values from the order-symbol when trailing stoploss

1.07
- added news filter ( needs FFCal indicator to be installed)
- fixed dashboard refresh issue

1.06
- fixed bug with trailing stop 
- fixed bug that EA was opening just 1 order even if there where valid signals on multiple pairs
- dashboard: show buy/sell signal when all indicators are valid
- cleaned up code

1.05
- fixed bug dashboard was not refreshing somtimes when switching between timeframes

1.04
- added (hidden) trailing stoploss/profit
- fixed some false signals

1.03
- added auto trading feature
- added sending notifications to mobile and alerts to alert window

1.02
- made it work on any timeframe

1.01
- EA now only show pairs where setups are starting to happen
- made moving average period and moving average type configurable
- made # candles to look back for zigzag, mbfx, trendline configurable
- fixed some small bugs

1.00
- initial version
