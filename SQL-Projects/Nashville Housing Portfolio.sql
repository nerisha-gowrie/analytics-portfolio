/* ====================================================
NASHVILLE HOUSING DATA CLEANING (SQL Server)
Database: PortfolioProject
Table: dbo.NashvilleHousing

Goal:
- Standardise date format
- Populate missing PropertyAddress using ParcelID (self-join)
- Split addresses into separate columns
- Standardise SoldAsVacant values (Y/N -> Yes/No)
- Identify duplicates
- Drop unsed columns (final cleanup)

======================================================= */ 


/* ====================================================
QUICK LOOK AT DATA
======================================================= */ 

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;


/* ===================================================
1. STANDARDISE SaleDate COLUMN
- Remove time component
- Convert to DATE datatype
====================================================== */ 

-- Preview conversion before update
SELECT SaleDate, CONVERT(DATE, SaleDate) AS ConvertedSaleDate
FROM PortfolioProject.dbo.NashvilleHousing;

-- Apply update to remove time component
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate);

-- Permantly change column datatype to DATE
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ALTER COLUMN SaleDate DATE;


/* ===================================================
2. POPULATE MISSING PropertyAddress (Self-Join)
- Assumption: Same ParcelID = same PropertyAddress
====================================================== */ 

-- Preview nulls
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

-- Preview match logic
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Update null PropertyAddress values
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


/* ===================================================
3. SPLIT PropertyAddress INTO Address + City
====================================================== */ 


-- Preview split
SELECT PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS Address
FROM PortfolioProject.dbo.NashvilleHousing;

-- Add new columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

-- populate new columns
UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


/* ===================================================
4. SPLIT OwnerAddress INTO Address + City + State
- Using PARENAME trick (works after replacing commas)
====================================================== */ 

-- Preview split
SELECT OwnerAddress, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing;

-- Add new columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

-- Populate new columns
UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


UPDATE  PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE  PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID


/* ===================================================
5. STANDARDISE SoldAsVacant VALUES (Y/N -> Yes/No)
====================================================== */ 

-- Check current values
SELECT Distinct(SoldAsVacant), COUNT(SoldASVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Preview transformation
SELECT SoldAsVacant,
CASE
	WHEN SoldASVacant = 'N' THEN 'No'
	WHEN SoldASVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant
END
FROM PortfolioProject.dbo.NashvilleHousing;

-- Apply update
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = 
CASE
	WHEN SoldASVacant = 'N' THEN 'No'
	WHEN SoldASVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant
END;


/* ===================================================
6. IDENTIFY DUPLICATES
- Using Row_Number over key columns 
====================================================== */ 

WITH RowNumCTE AS(
SELECT *, 
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			ORDER BY
			UniqueID
			) row_num

FROM PortfolioProject.dbo.NashvilleHousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


/* ===================================================
7. DROP UNUSED COLUMNS (FINAL STEP)
====================================================== */ 

-- Preview before dropping
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

-- Drop columns no longer needed after splitting
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate