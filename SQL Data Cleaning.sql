SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

--Standardize date format (datetime to date)
ALTER TABLE	NashvilleHousing
ADD SaleDate2 date

UPDATE NashvilleHousing
SET SaleDate2 = CONVERT(date, SaleDate)

--Populate property address data (ParcelID has same property address)
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT nas1.ParcelID, nas1.PropertyAddress, nas2.UniqueID, nas2.PropertyAddress, ISNULL(nas1.PropertyAddress, nas2.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing nas1
JOIN PortfolioProject.dbo.NashvilleHousing nas2
	ON nas1.ParcelID = nas2.ParcelID
	AND nas1.UniqueID <> nas2.UniqueID
WHERE nas1.PropertyAddress IS NULL

UPDATE nas1
SET nas1.PropertyAddress = ISNULL(nas1.PropertyAddress, nas2.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing nas1
JOIN PortfolioProject.dbo.NashvilleHousing nas2
	ON nas1.ParcelID = nas2.ParcelID
	AND nas1.UniqueID <> nas2.UniqueID
WHERE nas1.PropertyAddress IS NULL

--Separate property address into individual parts (street, city) -> use SUBSTRING
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE	NashvilleHousing
ADD PropertyAddressStreet nvarchar(255)

UPDATE NashvilleHousing
SET PropertyAddressStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE	NashvilleHousing
ADD PropertyAddressCity nvarchar(255)

UPDATE NashvilleHousing
SET PropertyAddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

--Separate owner address into individual parts (street, city, state) -> use PARSENAME
SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE	NashvilleHousing
ADD OwnerAddressStreet nvarchar(255)

UPDATE NashvilleHousing
SET OwnerAddressStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE	NashvilleHousing
ADD OwnerAddressCity nvarchar(255)

UPDATE NashvilleHousing
SET OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE	NashvilleHousing
ADD OwnerAddressState nvarchar(255)

UPDATE NashvilleHousing
SET OwnerAddressState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Standardize "SoldAsVacant" field - update Y and N to Yes and No 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

--Remove duplicates
WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num
FROM PortfolioProject.dbo.NashvilleHousing
--ORDER BY ParcelID
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--Delete unused columns (usually applicable in views)
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress