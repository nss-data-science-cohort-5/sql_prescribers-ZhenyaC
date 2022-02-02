
--1a: Pindley
SELECT npi, nppes_provider_last_org_name, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi, nppes_provider_last_org_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;

--1b
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi, nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;

--2a Family Practice
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;

--2b Nurse Practiotioner
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag ='Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;

Select *
from prescription
LIMIT 5;

Select *
from prescriber
LIMIT 5;

--2c. Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT DISTINCT prescriber.specialty_description
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE prescription.drug_name IS NULL
	
--2d. Do not attempt until you have solved all other problems!
---For each specialty, report the percentage of total claims by that specialty which are for opioids. 
---Which specialties have a high percentage of opioids?


SELECT t.specialty_description, 100. * o.total_claims / t.total_claims 
FROM (SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag ='Y'
GROUP BY specialty_description)  o
INNER JOIN 
(SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description)  t
ON t.specialty_description = o.specialty_description;




