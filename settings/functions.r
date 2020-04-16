

formula.gen = function(D,I) as.formula(paste0(D, " ~ ", I)) %>%	return

formula.append = function(frm, string){
	paste0(frm %>% as.character %>% paste0(collapse = " "), " ", string) %>% return
}

# convert p-value into a star range
sig = function (x){
	y = c()
	for (i in seq_along(x)) {
		if      (x[i] <0 || x[i] > 1 || is.nan(x))  y[i] = 'error'
		else if (x[i] < 0.001                    )  y[i] = '***'
		else if (x[i] < 0.01                     )  y[i] = '**'
		else if (x[i] < 0.05                     )  y[i] = '*'
		else if (x[i] < 0.1                      )  y[i] = '.'
		else                                        y[i] = ' '
	}
	return(y)
}

round.d =function(x, d) x %>% round(digits = d) %>% format(nsmall = d) %>% return
format_pc = function(x) x %>% multiply_by(100) %>% round.d(1)
format_count = function(x) x %>% formatC(format = 'f', big.mark = ',', digits = 0)
