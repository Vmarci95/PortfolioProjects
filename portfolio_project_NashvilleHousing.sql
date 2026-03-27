CREATE TABLE PropertySales (
    UniqueID INT PRIMARY KEY,
    ParcelID VARCHAR(256),
    LandUse VARCHAR(256),
    PropertyAddress VARCHAR(256),
    SaleDate DATE,
    SalePrice TEXT,
    LegalReference VARCHAR(256),
    SoldAsVacant VARCHAR(256),
    OwnerName VARCHAR(256),
    OwnerAddress VARCHAR(256),
    Acreage TEXT,
    TaxDistrict VARCHAR(256),
    LandValue INT,
    BuildingValue INT,
    TotalValue DECIMAL(10,2),
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);
DROP TABLE PropertySales

--Clean SalePrice by removing '$' and spaces, then convert from TEXT to INT

ALTER TABLE PropertySales
ALTER COLUMN SalePrice TYPE INT
USING REPLACE(REPLACE(TRIM(SalePrice), '$', ''), ' ', '')::INT;

--Standardize decimal format (',' to '.') and convert Acreage from TEXT to DECIMAL

ALTER TABLE PropertySales
ALTER COLUMN Acreage TYPE DECIMAL(10,2)
USING REPLACE(Acreage::TEXT, ',', '.')::DECIMAL(10,2);

-- Populate Property Address data

SELECT propertyaddress FROM PropertySales 
WHERE propertyaddress IS NULL

-- Impute missing PropertyAddresses by looking up another record with the same ParcelID but different uniqueid

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, COALESCE(a.PropertyAddress, b.PropertyAddress) AS PropertyAddressFilled
FROM PropertySales a
JOIN PropertySales b
ON a.parcelid=b.parcelid
AND a.uniqueid!=b.uniqueid
WHERE a.propertyaddress IS NULL

--Update PropertySales table using the upper query

UPDATE PropertySales a
SET PropertyAddress = b.PropertyAddress
FROM PropertySales b
WHERE a.PropertyAddress IS NULL AND a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID;

-- Breaking out Address into Individual Columns (Address, City, State)
--owneradress

SELECT owneraddress,
TRIM(SPLIT_PART(owneraddress,',', 1)) AS split_address,
TRIM(SPLIT_PART(owneraddress,',', 2)) AS split_city,
TRIM(SPLIT_PART(owneraddress,',', 3)) AS split_state
FROM propertySALES

ALTER TABLE PropertySales ADD split_owneraddress VARCHAR(256)

UPDATE PropertySales SET split_owneraddress=TRIM(SPLIT_PART(owneraddress,',', 1))

ALTER TABLE PropertySales ADD split_ownercity VARCHAR(256)

UPDATE PropertySales SET split_ownercity=TRIM(SPLIT_PART(owneraddress,',', 2))

ALTER TABLE PropertySales ADD split_ownerstate VARCHAR(256)

UPDATE PropertySales SET split_ownerstate=TRIM(SPLIT_PART(owneraddress,',', 3))

SELECT owneraddress, propertyaddress, split_owneraddress, split_ownercity, split_ownerstate FROM PropertySales

-- SPLITTING propertyadress to 2 columns

ALTER TABLE PropertySales ADD split_propertyaddress VARCHAR(256)

UPDATE PropertySales SET split_propertyaddress=TRIM(SPLIT_PART(propertyaddress,',', 1))

ALTER TABLE PropertySales ADD split_propertycity VARCHAR(256)

UPDATE PropertySales SET split_propertycity=TRIM(SPLIT_PART(propertyaddress,',', 2))

SELECT split_propertyaddress, split_propertycity FROM PropertySales

-- Change Y and N to Yes and No in "Sold as Vacant" field

select DISTINCT(soldasvacant), COUNT(soldasvacant) from PropertySales 
group by soldasvacant
ORDER BY 2

select soldasvacant,
CASE WHEN soldasvacant='Y' THEN 'Yes'
	 WHEN soldasvacant='N' THEN 'No'
ELSE soldasvacant
END
FROM PropertySales

UPDATE PropertySales SET soldasvacant=CASE WHEN soldasvacant='Y' THEN 'Yes'
	 										WHEN soldasvacant='N' THEN 'No'
											ELSE soldasvacant
											END

select DISTINCT(soldasvacant), COUNT(soldasvacant) from PropertySales 
group by soldasvacant
ORDER BY 2


-- Remove Duplicates

SELECT *, ROW_NUMBER()OVER
(PARTITION BY parcelid, propertyaddress, saledate, saleprice, legalreference
ORDER BY uniqueid) AS row_num
FROM PropertySales
ORDER BY parcelid
--WHERE row_num>1  -> DOESN'T WORK USE CTE INSTEAD

--CTE FROM THE ROW_NUM

WITH row_num_cte AS(
SELECT *, ROW_NUMBER()OVER
(PARTITION BY parcelid, propertyaddress, saledate, saleprice, legalreference
ORDER BY uniqueid) AS row_num
FROM PropertySales)
/*DELETE FROM PropertySales					--step 2.
WHERE uniqueid IN (
SELECT uniqueid FROM row_num_cte
WHERE row_num>1)*/

SELECT * 
FROM row_num_cte
WHERE row_num>1

--Delete unused columns

ALTER TABLE PropertySales DROP COLUMN propertyaddress, DROP COLUMN owneraddress, DROP COLUMN taxdistrict 
Table PropertySales

SELECT acreage from propertysales where acreage is null