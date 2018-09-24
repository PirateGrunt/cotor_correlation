
--- 
title: "Correlations background"
author: "Brian A. Fannin ACAS"
date: "2018-08-29"
site: bookdown::bookdown_site
documentclass: book
classoption: table
bibliography: [book.bib, packages.bib]
biblio-style: apalike
link-citations: yes
description: "This is a set of notes about correlation and various other items that are correlated with correlation."
---



<!--chapter:end:index.Rmd-->


# Revisiting Wang

A brief set of notes on [@Wang]; a seminal paper on portfolio modeling for insurance.

Thoughts, thinkity, thunk.

<!--chapter:end:ch_wang.Rmd-->


# Example data


```r
library(tidyverse)
library(quantmod)
```



```r
get_fx_tibble <- function(which_fx) {

  obj_xts <- getFX(which_fx, auto.assign = FALSE) %>% 
    as.data.frame() %>% 
    as_tibble(rownames = 'date')
  
}

tbl_fx <- map_dfc(
    c('USD/GBP', 'USD/EUR', 'USD/CAD'), get_fx_tibble
  ) %>% 
  select(-date1, -date2) %>% 
  mutate(date = as.Date(date)) %>% 
  select_all(gsub, pattern = 'USD.', replacement = '') %>% 
  tidyr::gather(currency, rate, -date) %>% 
  group_by(currency) %>% 
  arrange(date) %>% 
  mutate(
      rate_change = rate / dplyr::lag(rate) - 1
    , normalized_rate = rate / first(rate)
  ) %>% 
  ungroup()

save(
  tbl_fx
  , file = file.path('data', 'fx.rda')
)
```


```r
tbl_fx %>% 
  ggplot(aes(date, rate, color = currency)) + 
  geom_line()
```



\begin{center}\includegraphics[width=0.75\linewidth]{ch_example_data_files/figure-latex/unnamed-chunk-4-1} \end{center}


```r
tbl_fx %>% 
  ggplot(aes(date, normalized_rate, color = currency)) + 
  geom_line()
```



\begin{center}\includegraphics[width=0.75\linewidth]{ch_example_data_files/figure-latex/unnamed-chunk-5-1} \end{center}


```r
tbl_fx %>% 
  ggplot(aes(date, rate_change, color = currency)) + 
  geom_line()
#> Warning: Removed 3 rows containing missing
#> values (geom_path).
```



\begin{center}\includegraphics[width=0.75\linewidth]{ch_example_data_files/figure-latex/unnamed-chunk-6-1} \end{center}


```r
tbl_fx %>% 
  select(-rate_change) %>% 
  tidyr::spread(currency, rate) %>% 
  ggplot(aes(CAD, GBP)) +
  geom_point()
#> Warning: Removed 534 rows containing missing values
#> (geom_point).
```



\begin{center}\includegraphics[width=0.75\linewidth]{ch_example_data_files/figure-latex/unnamed-chunk-7-1} \end{center}

A visual inspection of the plot suggests that _changes_ in FX are not as strongly correlated.


```r
tbl_fx %>% 
  select(-rate) %>% 
  tidyr::spread(currency, rate_change) %>% 
  ggplot(aes(CAD, GBP)) +
  geom_point()
#> Warning: Removed 535 rows containing missing values
#> (geom_point).
```



\begin{center}\includegraphics[width=0.75\linewidth]{ch_example_data_files/figure-latex/unnamed-chunk-8-1} \end{center}


<!--chapter:end:ch_example_data.Rmd-->


# Copula refresher

What's a copula? It's a multivariate distribution, with support on $\Re^N$. We use them to simulate multivariate losses which need not be independent and identically distributed.

## Support in R packages

Comes primarily from the `copula` package though there are some others. 




```r
library(copula)
```

## Visualize multivariate data

### Simulations

### Actual data

Load in our sample FX data.


```r
load(
  file = file.path('data', 'fx.rda')
)
```


```r
mat_obs <- tbl_fx %>% 
  select(date, currency, rate_change) %>% 
  filter(!is.na(rate_change)) %>% 
  tidyr::spread(currency, rate_change) %>% 
  select(-date) %>% 
  as.matrix()

mat_pseudo <- mat_obs %>% 
  copula::pobs()
```



```r
plt_obs <- mat_obs %>% 
  as.data.frame() %>% 
  ggplot(aes(CAD, EUR)) + 
  geom_point()

plt_pseudo <- mat_pseudo %>% 
  as.data.frame() %>% 
  ggplot(aes(CAD, EUR)) + 
  geom_point()

grid.arrange(plt_obs, plt_pseudo, nrow = 1)
```



\begin{center}\includegraphics[width=0.75\linewidth]{ch_copula_review_files/figure-latex/unnamed-chunk-6-1} \end{center}

## Fitting a copula

[@Charpentier] references four methods for fitting a copula. The example below will use maximum likelihood.


```r
fit_fx <- fitCopula(
    gumbelCopula(dim = 3)
  , data = mat_pseudo
  , method = 'ml'
)

fit_fx
#> Call: fitCopula(copula, data = data, method = "ml")
#> Fit based on "maximum likelihood" and 178 3-dimensional observations.
#> Copula: gumbelCopula 
#> alpha 
#>   1.6 
#> The maximized loglikelihood is 80.4 
#> Optimization converged
confint(fit_fx)
#>       2.5 % 97.5 %
#> alpha  1.47   1.74
```

Another example from [@Charpentier] using loss and ALAE data.


```r
library(CASdatasets)
data("lossalae")
```


```r
lossalae %>% 
  ggplot(aes(Loss, ALAE)) + 
  geom_point() + 
  scale_x_log10() + 
  scale_y_log10()
```



\begin{center}\includegraphics[width=0.75\linewidth]{ch_copula_review_files/figure-latex/unnamed-chunk-9-1} \end{center}


<!--chapter:end:ch_copula_review.Rmd-->


# Copula literature review

## Textbooks

There are at least two textbooks which give a foundational presentation of copulas for actuaries. The first is [@Charpentier]. I have a physical copy of this book and it's pretty good. The second is [@Parodi], which I'd never heard of until I did a search on O'Reilly's Safari service. It's very broad, but the chapter on multiline modeling looks promising.

[@Nelsen] is a book that I borrowed from a colleague in Munich. Hoo-boy. The first chapter was super mathy and not terribly grounded. I couldn't get past it. Enter at your own risk.

[@Hofert] looks promising. Against my better judgment, I might buy a copy. It was written by the same people who wrote the `copula` package, so there you are.

[@Joe] is another interesting one that I stumbled across. Harry Joe - the author - gets name checked in [@MultivariateCopulas]. 

## Variance

* Multivariate Copulas for Financial Modeling  [@MultivariateCopulas]

* Dependence Models and the Portfolio Effect [@DependenceModels]

* Quantifying Correlated Reinsurance Exposures with Copulas [@QuantifyingCorrelatedReinsurance]

* Tails of copulas

Here, Venter [@VenterTails] talks through some issues about dependence in the tail of the copula.

Venter introduces measurements for right and left tail concentration:

$$R(z) = Pr(U > z | V > z)$$

### Multivariate Copulas for Financial Modeling 

[@MultivariateCopulas] looks at the issues associated with copulas higher than bivariate. 

We learn about a few new copulas: the IT, and the Joe.

As an example, the authors fit several copulas to currency exchange data.



<!--chapter:end:ch_copula_literature.Rmd-->


# Stochastic Reserving Review

This will largely follow the thread of [@TaylorMcGuire].


```r
library(raw)
library(tidyverse)
```


```r
tbl_njm <- raw::NJM_WC %>% 
  select(-GroupCode, -Company, -Single) %>% 
  mutate(
      prior_cumulative_paid = dplyr::lag(CumulativePaid)
    , incremental_paid = coalesce(
          CumulativePaid - prior_cumulative_paid
        , CumulativePaid
      )
    , upper = DevelopmentYear <= 1997
  )

tbl_link_ratio <- tbl_njm %>% 
  filter(upper) %>% 
  group_by(Lag) %>% 
  summarise(
    link_ratio = sum(CumulativePaid) / sum(prior_cumulative_paid)
  ) %>% 
  ungroup() %>% 
  mutate(Lag = Lag - 1)
```


<!--chapter:end:ch_stochastic_reserving_review.Rmd-->


# Stochastic Reserving Literature

## The fundamental question

Or, possibly questions. Correlation is an inherently multivariate approach. Loss reserving tends to be univariate.

## The emergence of stochastic loss reserving

In a dreadful bit of editing, I'll first talk about the heuristic/deterministic approaches to loss reserving. This is the "meanwhile" part of our story. An early reference comes from Tarbell. Bornhuetter-Ferguson appears in 1972. Stanard shows up in 198?.

The earliest reference that I've seen to stochastic reserving, so far, has been something from Hachemeister and Stanard. This appears to have been a presentation at the ASTIN colloquium in Portugal in 1975. Although this paper is mentioned in quite a number of locations, specific citations vary. For instance, [@TaylorMcGuire] refer to it having appeared it at the spring meeting of the CAS. The CAS website [@CAS-bum-link] lists ASTIN colloquium, but does not provide a link.

Whatever. For about 15 years now, I had thought that the next reference came from [@Zehwirth1994], which - in my brain - had appeared in 1980. I was mistaken. Zehnwirth appeared in 1994. Possibly, I fixed that number in my head when I saw the year for [@Christofides1980]. However, I'm pretty sure that _this_ is also wrong. The Christofides reference is for a textbook from the Institute of Actuaries, published in 1989. 

(Fun fact: [@Christofides] gets name checked on Markus Gesman's blog (https://magesblog.com/post/2013-01-08-reserving-based-on-log-incremental/), based on a blog post that I wrote!)

And again, whatever. There is a paper from Erhard Kremer which appeared in 1982 in the Scandanavian Actuarial Journal. I don't have access to it, but the title "IBNR CLAIMS AND THE TWO-WAY MODEL OF ANOVA" sounds very much like the method which Christofides uses.

[@Verrall1991] also considers loglinear models. Article is behind a paywall.

[@DeJongAndZehnwirth1983] produced something.

We can say [@Taylor1986] included material on Hachemeister and Stanard. (See here: https://actuaries.asn.au/Library/Events/Conventions/2007/8.e_Conv07_ppt_Taylor_Recent%20stochastic%20developments%20of%20the%20chain%20ladder.pdf).I don't have access to a copy of the Taylor text, so will have to take his word for it.

Subsequent references are [@Mack1991], [@Neuhaus2004]

## Multivariate loss reserving

[@Braun-2004]

### Reserving and credibility

This is not correlations per se, but it's definitely in that direction. Credibility presumes a multivariate (categorical) data structure. So, at a minimum we are not looking at a block of reserves in isolation.

## Recent stuff

[@HappMeierMerz] This is a difficult one.

##

To sort:

* file:///home/mojo/Downloads/crm2-D5.pdf
* file:///home/mojo/Downloads/Claims%20Reserving%20Manual%20V2%20complete.pdf
* file:///home/mojo/Downloads/Claims%20Reserving%20Manual%20V1%20complete.pdf
* file:///home/mojo/Downloads/sm0201.pdf
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=5248
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=6735
* https://www.actuaries.org/LIBRARY/ASTIN/vol39no1/35.pdf
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=3390
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=3183
* https://www.casact.org/pubs/forum/94spforum/94spf393.pdf
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=2516
* https://www.cass.city.ac.uk/__data/assets/pdf_file/0018/354600/prediction-rbns-ibnr-claims-cass-knowledge.pdf
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=2911
* https://www.casact.org/pubs/forum/98fforum/zehnwirth.pdf
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=640
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=2378
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=2517
* https://www.casact.org/pubs/forum/94spforum/94spf447.pdf
* https://www.casact.org/research/dare/index.cfm?fa=view&abstrID=627
* file:///home/mojo/Downloads/0157-0181.pdf

<!--chapter:end:ch_stochastic_reserving_literature.Rmd-->


# Solvency Regulation Literature

Solvency I, solvency II
Solvency me, solvency you!!

<!--chapter:end:ch_solvency_regulation_literature.Rmd-->






<!--chapter:end:ch_references.Rmd-->

