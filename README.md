# SQL World Layoff Data Cleaning

This data cleaning uses worldwide layoff data from March 2020 to March 2023.

I first copied the dataset into a new table to avoid altering the original data. This gave me the opportunity to add an additional column which marked duplicate entries. I deleted any duplicate entries as well as any entries missing critical data.

The most important columns of the table were total_laid_off and percentage_laid_off. When both those values were missing, the entire row was unusable because I didn't know if a layoff had actually happened. So, any rows missing both total_laid_off and percentage_laid_off were deleted.

I standardized the data by trimming whitespace, changing the date column from string to DATE objects, and removing variants within the industry column. For example, the industry column contained both "Crypto" and "Crypto Currency" which should be the same industry, so "Crypto Currency" was changed to "Crypto".

I addressed the blank and NULL values by first standardizing them; any blank strings were changed to NULL values. Then I filled the NULL data where possible. For entries missing an industry, I was generally able to find another entry from the same company that did have the industry data, so I was able to use that to fill in most of the NULL industry data.

Finally, I exported the cleaned dataset as a csv file which is included in this repository.