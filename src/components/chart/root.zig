//! Chart family. Each chart builds its own SVG into a caller-provided
//! scratch buffer and hands it to `zui.svg` (zui rasterizes SVG elements).

pub const area = @import("area.zig");
pub const bar = @import("bar.zig");
pub const boxplot = @import("boxplot.zig");
pub const candlestick = @import("candlestick.zig");
pub const composed = @import("composed.zig");
pub const funnel = @import("funnel.zig");
pub const gauge = @import("gauge.zig");
pub const geometry = @import("geometry.zig");
pub const hbar = @import("hbar.zig");
pub const heatmap = @import("heatmap.zig");
pub const line = @import("line.zig");
pub const pie = @import("pie.zig");
pub const radar = @import("radar.zig");
pub const scatter = @import("scatter.zig");
pub const sparkline = @import("sparkline.zig");
pub const stacked = @import("stacked.zig");
pub const treemap = @import("treemap.zig");
pub const waterfall = @import("waterfall.zig");

pub const AreaChart = area.AreaChart;
pub const Series = area.Series;
pub const MAX_POINTS = area.MAX_POINTS;
pub const niceDomain = area.niceDomain;
pub const hexString = area.hexString;

pub const BarChart = bar.BarChart;
pub const Box = boxplot.Box;
pub const BoxPlot = boxplot.BoxPlot;
pub const Candle = candlestick.Candle;
pub const Candlestick = candlestick.Candlestick;
pub const ComposedChart = composed.Composed;
pub const FunnelChart = funnel.FunnelChart;
pub const GaugeChart = gauge.GaugeChart;
pub const HBarChart = hbar.HBar;
pub const Heatmap = heatmap.Heatmap;
pub const LineChart = line.LineChart;
pub const PieChart = pie.PieChart;
pub const RadarChart = radar.Radar;
pub const ScatterChart = scatter.ScatterChart;
pub const ScatterPoint = scatter.Point;
pub const Sparkline = sparkline.Sparkline;
pub const StackedAreaChart = stacked.StackedAreaChart;
pub const StackedBarChart = stacked.StackedBarChart;
pub const Treemap = treemap.Treemap;
pub const WaterfallChart = waterfall.Waterfall;

test {
    @import("std").testing.refAllDecls(@This());
}
