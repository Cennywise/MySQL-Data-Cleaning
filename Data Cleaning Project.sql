-- Data Cleaning

SELECT *
FROM world_layoffs.layoffs;



-- 0. Create Staging Dataset
CREATE TABLE world_layoffs.layoffs_staging
LIKE world_layoffs.layoffs;

INSERT world_layoffs.layoffs_staging
SELECT *
FROM world_layoffs.layoffs;



-- 1. Remove Duplicates
-- Wishful Thinking
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Casper';

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging
)
DELETE
FROM duplicate_cte -- Doesn't work because CTEs can't be updated.
WHERE row_num > 1;

-- Actual Way
CREATE TABLE world_layoffs.`layoffs_staging2`
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

INSERT INTO world_layoffs.layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;

DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- Verify Success
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;



-- 2. Standardize Data
-- company
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE LEFT(company, 1) = ' ';

SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);

-- industry
SELECT DISTINCT(industry)
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM world_layoffs.layoffs_staging2
-- WHERE industry = 'Crypto Currency' OR industry = 'CryptoCurrency'; -- My way
WHERE industry LIKE 'Crypto%';

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- location
SELECT DISTINCT(location)
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

-- country
SELECT DISTINCT(country)
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE country LIKE 'United States.%';

UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- date
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;



-- 3. Address Null or Blank Values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
    
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL OR industry = '';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Airbnb';

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Travel'
WHERE company = 'Airbnb';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = "Bally's Interactive";

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Carvana';

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Transportation'
WHERE company = 'Carvana';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Juul';

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Consumer'
WHERE company = 'Juul';

UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';


#This is how I should have done it.
UPDATE world_layoffs.layoffs_staging2 t1 JOIN world_layoffs.layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;



-- 4. Remove Unnecessary Columns
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL and percentage_laid_off IS NULL;

DELETE
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL and percentage_laid_off IS NULL;

ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM world_layoffs.layoffs_staging2;