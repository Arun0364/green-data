# Results

## QC Analysis

| Metric | Mouse Liver Replicate 1 | Mouse Liver Replicate 2 | Human Liver Replicate 1 | Human Liver Replicate 2 | Mouse Adrenal Gland Replicate 1 | Mouse Adrenal Gland Replicate 2 | Human Adrenal Gland Replicate 1 | Human Adrenal Gland Replicate 2 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| % Mapped Reads (%) | $\color{green}97.8$ | $\color{green}97.89999999999999$ | $\color{green}98.9$ | $\color{green}98.6$ | $\color{green}98.5$ | $\color{green}98.6$ | $\color{green}98.5$ | $\color{green}98.9$ |	
| % Properly Paired Reads (%) | $\color{green}95.7$ | $\color{green}95.6$ | $\color{green}97.89999999999999$ | $\color{green}97.5$ | $\color{green}94.6$ | $\color{green}94.6999999999999$ | $\color{green}97.0$ | $\color{green}97.5$ |
| Periodicity Plots | $\color{green}3 \text{ Clear, distinct}$<br>$\color{green} \text{humps}$ | $\color{green}3 \text{ Clear, distinct}$<br>$\color{green} \text{humps}$ | $\color{green}3 \text{ Clear, distinct}$<br>$\color{green} \text{humps}$ | $\color{green}3 \text{ Clear, distinct}$<br>$\color{green} \text{humps}$ | $\color{yellow}2 \text{ Clear, distinct}$<br>$\color{yellow} \text{humps}$ | $\color{yellow}2 \text{ Clear, distinct}$<br>$\color{yellow} \text{humps}$ | $\color{yellow}2 \text{ Clear and distinct}$<br>$\color{yellow} \text{humps}$ | $\color{yellow}2 \text{ Clear and distinct}$<br>$\color{yellow} \text{humps}$ |
| TSS-Enrichment Score | $\color{yellow}7.692382151686117$ | $\color{yellow}7.354598361825624$ | $\color{green}23.294805448649445$ | $\color{green}20.962438980086663$ | $\color{green}18.365117628803656$ | $\color{green}18.997852749462098$ | $\color{green}26.084253634636482$ | $\color{green}14.011771178374902$ |
| NRF (Non-Redundant Fraction) | $\color{green}0.935887$ | $\color{green}0.94404$ | $\color{green}0.884593$ | $\color{green}0.899531$ | $\color{red}0.301612$ | $\color{red}0.270462$ | $\color{yellow}0.778014$ | $\color{green}0.969527$ |
| Rescue Ratio | $\color{green}1.0043626038838573$ | $\color{green}1.0122929315643505$ | $\color{green}1.0906310179587084$ | $\color{green}1.24175568252391$ | $\color{green}1.013263779368353$ | $\color{green}1.0098552058921995$ | $\color{red}2.0842882741797046$ | $\color{red}4.283663165487085$ |
| Self-consistency Ratio | $\color{green}1.0756982081825852$ | $\color{green}1.1043673083661616$ | $\color{green}1.2192105681999046$ | $\color{green}1.4284339019600292$ | $\color{green}1.2220589050973432$ | $\color{green}1.2891362811933205$ | $\color{red}3.6038942470169237$ | $\color{red}6.26995057660626$ |
| Reproducibility Test | $\color{green}\text{Pass}$ | $\color{green}\text{Pass}$ | $\color{green}\text{Pass}$ | $\color{green}\text{Pass}$ | $\color{green}\text{Pass}$ | $\color{green}\text{Pass}$ | $\color{red}\text{Fail}$ | $\color{red}\text{Fail}$ |

> $\color{green}\text{Green}$ =  Passes threshold — $\color{yellow}\text{Yellow}$ = Marginal — $\color{red}\text{Red}$ = Fails threshold

## HALPER Analysis

| Category                  | Number of Peaks |
|---------------------------|-----------------|
| Human OCRs                | 128,816         |
| Mouse OCRs                | 264,873         |
| Shared (halLiftover)      | 3,508,003       |
| Shared (HALPER)           | 65,315          |

## rGREAT Analysis

Plots for the GO analysis are availbale in the [rGREAT Plots](../rGREAT_Analysis/outputs/plots) directory.

## MEME-ChIP Analysis

### Top TF-matched MEME motif (left) and secondary motif (right) per OCR category. Letter height ∝ information content (bits).

![Motif analysis](../Motif.png)

### Top MEME and STREME motif per OCR category (TomTom/JASPAR 2026 matches; q < 0.05).

| OCR Category | Top MEME motif | MEME E-value | Top STREME motif | STREME E-value |
| --- | --- | --- | --- | --- |
| Shared enhancers | CTCF (MA0139.2) | $8.8×10^{-461}$ | CTCF/KLF4 | $1.3×10^{-42}$ |
| Human enhancers | CTCF (MA0139.2) | $4.3×10^{-116}$ | CTCF | $4.6×10^{-60}$ |
| Human-specific enhancers | poly-T (MA2593.1) | $1.5×10^{-55}$ | CTCF/KLF4 | $3.4×10^{-13}$ |
| Human promoters | SP/KLF;KLF8 (MA2681.1) | $3.3×10^{-74}$ | KLF8/ NF-Y/ZNF143 | $7.6×10^{-13}$ |
| Mouse enhancers | CTCF (MA1929.2) | $1.2×10^{-184}$ | CTCF/PPARδ/FOXC2 | $3.3×10^{-146}$ |
| Mouse-specific enhancers | CTCF (MA0139.2) | $1.1×10^{-182}$ | CTCF/PPARα::RXRα/FOXD3 | $3.2×10^{-96}$ |
| Mouse promoters | SP/KLF;CTCF (MA0139.2) | $2.8×10^{-37}$ | KLF8/CTCF/PPARδ | $7.0×10^{-12}$ |


