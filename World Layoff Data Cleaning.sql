# Uncleaned Dataset
SELECT *
FROM world_layoffs.layoffs;

#1. Create Staging Dataset
CREATE TABLE world_layoffs.layoffs_staging
(
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# Insert data
INSERT INTO world_layoffs.layoffs_staging
# A row_num column is added to easily detect duplicates
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs;



#2. Delete Duplicates
DELETE
FROM world_layoffs.layoffs_staging
WHERE row_num > 1;

# Drop row_num since it's no longer needed
ALTER TABLE world_layoffs.layoffs_staging
DROP COLUMN row_num;

#3. Standardize Data
# company: Trim whitespace
# Find entries with unnecessary whitespace
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company != TRIM(company);

# Compare untrimmed with trimmed
SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging
WHERE company != TRIM(company);

UPDATE world_layoffs.layoffs_staging
SET company = TRIM(company);

# industry: Standardize crypto variants
# Look for redundant industries
SELECT DISTINCT(industry)
FROM world_layoffs.layoffs_staging
ORDER BY industry;

# Find crypto variants
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry LIKE 'Crypto%' AND industry != 'Crypto';

# Rename redundant crypto industries
UPDATE world_layoffs.layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

# location: Location is fine
SELECT DISTINCT(location)
FROM world_layoffs.layoffs_staging
ORDER BY 1;

# country: Standardize variations of United States
# Look for redundant countries
SELECT DISTINCT(country)
FROM world_layoffs.layoffs_staging
ORDER BY 1;

# Find variations of United States
SELECT *
FROM world_layoffs.layoffs_staging
WHERE country LIKE 'United States%' AND country != 'United States';

# Standardize United States entries
UPDATE world_layoffs.layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

# date: Convert strings dates to DATE objects
# Compare formats
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM world_layoffs.layoffs_staging;

# Modify format of date entries
UPDATE world_layoffs.layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

# Convert date entries to DATE objects
ALTER TABLE world_layoffs.layoffs_staging
MODIFY COLUMN `date` DATE;



# 4. Address Blank and Null Values
# Some companies have multiple entries. Some entries may be are missing the industry data while others have it.
# If at least one entry from a company has the industry data, the other entries with an empty industry can be filled in.

# Find entries without industry data
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry IS NULL OR TRIM(industry) = '';

# Standardize data by converting whitespace to NULL
UPDATE world_layoffs.layoffs_staging
SET industry = NULL
WHERE TRIM(industry) = '';

# Self-join the table on company.
# This will have the effect of pairing entries within a company that don't have industry data to entries that does have the data.
# When such a pairings happen, the industry data is copied into the empty entry.
UPDATE world_layoffs.layoffs_staging t1 JOIN world_layoffs.layoffs_staging t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

# The only entry this doesn't work for is Bally's Intereactive since that company only has one entry.
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = "Bally's Interactive";



# 5. Remove Unnecessary Rows and Columns
# Find entries with no layoff data
SELECT *
FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL and percentage_laid_off IS NULL;

# Delete those entries
DELETE
FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL and percentage_laid_off IS NULL;

# Cleaned Dataset
SELECT *
FROM world_layoffs.layoffs_staging;