.a = 1.2

pdfPlotDim = list(w=3.7*.a, h=2.5*.a)
eggPanelSize = list(w=3*.a, h=3*.a)
hline0 = geom_hline(yintercept = 0, size = 0.1, lty = 2)

theme1 = function(){
  theme(
    panel.grid = element_blank(),
    axis.line.x = element_line(),
    axis.ticks.x = element_line(),
    axis.title.x = element_text(margin = margin(t = 15)),
    axis.title.y = element_text(margin = margin(r = unit(5, 'pt'))),
    legend.title = element_blank(),
    legend.position = 'bottom',
    panel.spacing = unit(.7, 'lines'),
    axis.title = element_text(size = 10),
    strip.text = element_text(size = 10),
  )
}
