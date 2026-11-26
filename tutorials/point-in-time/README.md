# Rebuild what was known at a decision time in base R

At 14:00:04, an analyst records the home team's price as **1.90**. The archive later shows a **2.10** update stamped 14:00:03. Was 1.90 a mistake? Check when the update arrived. The analyst received it at 14:00:06, two seconds after the decision. Giving the analyst 2.10 in a backtest introduces look-ahead bias.

[Try the six decision times in your browser][interactive]. The interactive version loads R and Shiny in your browser and uses the six fictional messages below. For the offline version, download [replay.R](replay.R) and run `Rscript replay.R` with base R.

| Selection | Source updated (UTC) | Received (UTC) | Decimal price |
|---|---|---|---:|
| Home | 14:00:01 | 14:00:02 | 1.90 |
| Away | 14:00:02 | 14:00:03 | 1.80 |
| Home | 14:00:03 | 14:00:06 | 2.10 |
| Home | 14:00:02 | 14:00:07 | 1.85 |
| Home | 14:00:08 | 14:00:09 | Withdrawn |
| Home | 14:00:10 | 14:00:11 | 1.97 |

Each selection here belongs to the same fictional event, bookmaker, period and moneyline market. In a real log, identify that entire stream before comparing records. Both clocks in this example share a UTC time base. The receipt timestamp records when the observation became available to this analyst.

## Watch two plausible shortcuts fail

Save the script, start R in that directory, and run these lines. Filtering on source time alone makes the delayed update visible too early.

```r
source("replay.R")
log <- example_log()
home <- log[log$stream == "home", ]
cutoff <- example_start() + 4
early <- home[home$updated <= cutoff, ]
early$price[which.max(early$updated)]  # 2.10
quote_at(log, "home", cutoff)$price   # 1.90
```

Now move to 14:00:07. The newest arrival contains the older 1.85 price. Picking the last message received would roll the quote backward.

```r
cutoff <- example_start() + 7
arrived <- home[home$received <= cutoff, ]
arrived$price[which.max(arrived$received)]  # 1.85
quote_at(log, "home", cutoff)$price         # 2.10
```

## Apply the two clocks in order

1. Keep messages for the selection whose receipt time is at or before the decision. If the set is empty, return `unseen`.
2. Among those messages, select the greatest source update time. Identical observations at that timestamp agree. If their state or price differs, return `conflict` with an unknown price. A feed with an authoritative revision sequence can resolve some of these ties.
3. Preserve withdrawals. At 14:00:09 the latest known state is `withdrawn`. Carrying the last numeric price across that gap would invent a quote. The new 1.97 observation becomes available at 14:00:11.

The same pattern applies to delayed sensor readings and corrections to operational reports. It depends on keeping the arrival history. A final snapshot with one timestamp per row cannot tell you when your own system first saw each revision.

## Check your implementation

Download [test_replay.R](test_replay.R) alongside the script, then run `Rscript test_replay.R` from that directory. The tests shuffle arrival order, append a conflicting observation, replay an exact cutoff and verify that a delayed message cannot reopen a withdrawn quote. Missing clock values and receipt times before the source update raise an error under the example’s clock assumptions.

For work with a real feed, record the two timestamp definitions and the selection identifiers in the [ParlayAPI evaluation lab](https://parlay-api.com/tools/evaluation-lab?utm_source=github&utm_medium=r_tutorial&utm_campaign=point_in_time_replay). ParlayAPI maintains this tutorial. All observations used here are synthetic.

[interactive]: https://shinylive.io/r/app/#code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAGwEsAjAJykYE8AKAZwAtaJWAlAB0InIgFdGBOOyFhGcVNSitsc3AAJqRAlGoaAvBoAqWAKoBRYRBHaA5hoA8AWg1wAHrCVwA%2BvfbW4rROrgBm1EEAJgAKUHYyIhoapHGcACQwUHxcpKzUcIYacpnuzgDutJGk3IgALAAcCjAA3JmMdnyIAExNGlDipETNqFCRkXx2iAAMGgCMTeqJSRrcs7JgAOq8BNwaAI7iROQro32MjLQAbnCRAPxyArhLSajrWIrKrH0aobQEpLQSHoVkR4M5yLANDASHA8nw4BgNABZIjXZLcAqROAEWicQEQZK0eDJIgaThwAplba7VAXaTogpQaDUVicUgnSIaBTSK43DAPJ4E5bMcZEABCA0GonW5OIEEi6iKYAAItjcfjCcT2GZjABhYR4Z7LY0mpI7Ih-OCcQrk0gAOVgVvYBHYU00tU0ADZNAB2TQATk0s1mjyNpvDEcjLygbLgU3Ws1q0ymiEVLrkUymioztWzYCmnrzUx9Rf9eeDDwEoaFUZN5Py-xuhQ9Gj4dAgBSMpks1eN3C67AABixaFBnHRroPCnJUEQ6ORFeR3KQAPIDVADdZMzhlOCMRVt%2BGFbtWXvLV5L1frzdyDxKJlQAEkA8QdudkzmU%2BCvsAZnWSKtTg4itLlsTgXlOXoL5qkxNU8RITU4AFI0UnofI11IDdSC3c4rj0TgHiWaxrHJRhrkYEIfnECB-nxdg%2BCwzQJEwgZNHJTh4IgAQNBAJYCAGIhQlCSiFCgWjrnYDwvHyHw2RYbDuIAaj6TgMD4ch4kYeiICwtJZRISIqyWBROHEah2RcUCxIBCSDiOXxH3YexNDkbhQSQvANH4wYhICIyhWY3Tt13CjLIUeU92MDxsN4msuREq0zIUo1aGE9hGD0lJjgMIw5Ds8gFTAbiFFISQIC4Wl1NCdYAAl3I0SrpEQDQAFIMC6UJFQyxq4H841Uo0dLMsfTtcrACpqkiZgyhsIrQNKxhyrkOriXyylaEm6bZusY05DtUk3NWw5jm5cDrkKpYAF8do0QKBjSO9lGgJ8CTCigsUYKLl3YWLjR3Dadm03T9Plb8TQzORpzAYwMS0IgHDlFI%2BGtZRyAotbVI0faOw5M4LnOjQqQodFcQ0LEcU4wmYyhUYEUWOKkjkXMwChmGCi6DBZhmcRUEiEaqetAhRIKvp2UTZNph-REAEl2RYfGQNIMpSRByJrSgUI0ZJ61yfVEh%2BUNBmlULFmxrZjQOa5jQeb5455d5a0pP%2BFlRYZLyBKEvp5Vba0ICIMo3DoDo0Lpw3TTkEtTaVABBMm4E%2BJtZgweoAFYoUA4CNAAK3ENk8YgmXSGtMRJHpG3%2BdJucPvRJk3ct7neZGg2wd2sAyyjuRzZLqR1s2uAA5g-ZjoRDRdXl1gJgtzmZlCIhGDKFhOWVszOT4a4yC9vpLiyZQQ4aulQ5b5Y5ArDvodh7v6VxUymygDQOwDta%2Bk1vc3Ym7gpqgBfqANo0buupYd1SBpHttvag1o3oRU%2BlAEOP0jSMH9hA1w9hgD2DSKdCCTgjDeUEtVR4GgAC6RpbZQAwKEZg8B2AAGV47YheoUBBZR0hslEjAI%2BtYzCNxFkYWejBMjYUYekcuBUXJgBajVRALUkSSKoYuAAXlDHUupkJG0jO8HkBMeFz34elRB6CwIQVEeIyR0iWqyM8qQBRY0lEqNrMaKhWV3yCOGuQTQ0QD4ML0T1f%2BmhxgdCLoULomhoBQ0ACgEhEICXREDwPgrBo7oHYEENie5yLWDwGAXIqAEDIEvGAS6uBwDQHgFQBQ95VA4HwIjCgpAqAAGINCxxYXASElRqmpVoCBGEPxaDLkkHATQ9AiBEAANaZGGXuTQbRxmkE0Fki4RBORMk5PWOh%2BJ%2BQQHqdHag%2BgiD0FItvF61o%2BDazcJ4GA3gzgFDXtUvkJgiQgRYAUJR6ypLnJknJRgFkwjUVoiQAIKkMDRBXFQ6WAANf46wuhTC6J6ZwXNnBTFmHMJMmZkzyMUXqCJIhXneD8PDSioQfkvX%2Bb9ZIMxLI4veSkT5AQlgkLIRQhIcUmmQmwesQ6HlRFfxUHmDlvL3L8vgIKjyZ4kjCKbEYUgMxlIulmJoIJGgfzys0PUIMUxRWgQ0RKslGgZXsAVUqjQ3oNB%2Bg0IGOYIYj5yWyl5dYa1CqiPtXmJ1nk8rDwdUqd%2Bn8ZrOvdbY88Hi2VJ39G6OYydQ31yDMnFOmg7TRx8KJagPgo3%2Bh9BqlhExODR04AAMWsnPa0Rgc3RwADJUIsEREQUSbAQDWj4R8BKiV0WcmSUgrDNA4KEtxUlbIiCoFSn7bCuIMD0vIY6Jy8MNURj0NQZ0Mo23NJgHmcVHq5AYPOnma1nKlQ9QeK1PgLV76Ok4BOuwVZ2HhmHTsFg1k9w5FYfg-IEA7DVHvYu7iOU5gls0AAQmHdAN9sB8EQDkderSLKYBTsvRADEFwi7Og9qEURQKQXgtIAKLQFAX3cAQz5UIH6jCzG-T7MhfANoyE7fhi9po%2BCwY2ietBK7kPArBf8DDtG9z0dPforVkRmOobY0VajJoZ30VUr8CA5HuMrvPX0bZYnSOSfINx9dNxz1hnDKJtBqnOQAD4jCMa4Wp39TJWBxu4xBqDppRMgbAxZhdQH8Fafhi4goLUD22rdfZVd40Nofy2pWYT-VVIQHEPAOk3HvE3XtZRNBW7DBjRdUsXt-bQiDvYKJ4dEmpNoJ6sAe1BDuIADI4Z2DSHlgrGhdNzCsyJ%2BT-6oCRYPsAH9BWqzWCWMMv2M1Yvw1QS5iDCXW2sI0CV7TBiCaOGwYhzQviEGoEKMWstFgiFChMklSio7GWAZgDaBzbD3Z4cKJRtijiobUXJBQemdjawrsKDGQFLG0PsDjQm5pSamIXA6ASMasxU1TARbMQH6LrGYqExpm7xoeqFFe4m5Nw3M3Zrzf8Ati3S3lpugNdgP6ICMPYF1-2XFipwAWuVdb5kOtrcSuZNId3LIlHx91iAtOjOGSWKjK0XyNAE5msAHnzO7ufvJ8ApjGg5t9rR8t1bSQt1IOtpJg4MgOdsmAOmMAW68y7qKoVpYWPcf%2BxyCNTg3FqtEe7fA6nwD4uWTkHKcIfx0NgAt6T9Klv-7GUt65yisvXMe9MjT6Hlkfe7qp-79DkSRAiCx5wVkGAIBjsoQRjQUwS3m6FPYSilLfD%2BBuqUz4sW0BKA4C6UNLZjWmvNcGfBhKaLEuNzxI0dbHIttcgKzyWfZLUoUrqsk-8bqVTIOwSIRAMC6Hk4wegfA%2BOgTKfgxhcfj2S4x1WkQ6TMnZIydFPJBCgA
