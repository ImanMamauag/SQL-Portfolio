-- Creating a staging table
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM layoffs_staging;

-- Importing all data from raw table to staging.
INSERT layoffs_staging 
SELECT * FROM layoffs;


SELECT * FROM layoffs;

-- Removing duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;


WITH duplicate_cte AS(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)

SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- Double checking if values are duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';


-- Creating another staging table because duplicates couldn’t be removed directly in the CTE.
CREATE TABLE `layoffs_staging2` (
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


SELECT *
FROM layoffs_staging2;


-- Importing all data from staging 1 to staging 2 with an added row_num column
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Finally we can delete the duplicate rows in the staging 2 table 
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Checking cleaning progress
SELECT *
FROM layoffs_staging2;


-- Standardizing Data


SELECT DISTINCT company, TRIM(company) 
FROM layoffs_staging2;

UPDATE layoffs_staging2 
SET company = TRIM(company);


SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- checking the supposed value for crypto
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Some values have a typo (trailing special character)
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Selecting United States.
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- Trimming a trailing special character
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%';

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update date format first YYYY-MM--DD
UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- Then update date type from text to date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;



-- Null or Blank Values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- delete rows, data will not be useful during EDA
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';


SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';


-- Self join to compare values then populate
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL

-- looking closely into t1.industry and t2.industry
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL

-- Changing blanks to nulls in the industry column
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


-- Update command to populate the null or blank values
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;

-- Checking the cleaning result
SELECT *
FROM layoffs_staging2;

-- Remove Any Columns
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;



