
--1a: Pindley
SELECT npi, nppes_provider_last_org_name, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi, nppes_provider_last_org_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;

--1b Family Practice
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi, nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;

--SELECT CONCAT('AB', 'CD')

-- to cancatenate first and last names
SELECT p1.npi, p1.nppes_provider_first_name || ' ' || p1.nppes_provider_last_org_name AS name, 
       p1.specialty_description AS specialty, SUM(p2.total_claim_count) AS total_claims 
	   FROM prescriber p1 JOIN prescription p2 ON p1.npi = p2.npi 
	   GROUP BY 1,2,3 
	   ORDER BY 4 DESC; 

--2a Family Practice
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;



--2b Nurse Practiotioner
--with formatting
SELECT specialty_description, TO_CHAR(SUM(total_claim_count),'fm999G999') AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag ='Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 10;


--2c. Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
--
SELECT DISTINCT prescriber.specialty_description
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE prescription.drug_name IS NULL

--V1
SELECT DISTINCT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
FULL JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY specialty_description
HAVING (SUM(total_claim_count) IS NULL)
ORDER BY total_claims; 

--V2
SELECT p1.specialty_description AS specialty, COALESCE(SUM(p2.total_claim_count), 0) AS total_claims 
FROM prescriber p1 LEFT JOIN prescription p2 ON p1.npi = p2.npi 
GROUP BY 1 
ORDER BY 2 ; 

--V3
SELECT DISTINCT pr.specialty_description,
COUNT(pn.total_claim_count) AS claim_cnt
FROM prescriber pr
LEFT JOIN prescription pn
ON pr.npi = pn.npi
GROUP BY pr.specialty_description
ORDER BY claim_cnt ASC; 

SELECT specialty_description
FROM prescriber
WHERE specialty_description NOT IN
(SELECT specialty_description
 FROM prescription
 INNER JOIN prescriber
 USING(npi))


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

--3a. Which drug (generic_name) had the highest total drug cost?
--SELECT generic_name, MAX(total_drug_cost)
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY generic_name, total_drug_cost
ORDER BY total_drug_cost DESC
LIMIT 10;


---V2
SELECT generic_name, SUM(total_drug_cost)::MONEY 
FROM prescription 
INNER JOIN drug 
USING(drug_name) 
GROUP BY generic_name 
ORDER BY 2 DESC; 


--3b. Which drug (generic_name) has the hightest total cost per day?

SELECT generic_name, 
	   ROUND(SUM(total_drug_cost)/SUM(total_30_day_fill_count), 2)::money AS total_cost_per_day
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC
LIMIT 10;

SELECT generic_name, total_drug_cost, ROUND(total_drug_cost/total_day_supply, 2) AS total_cost_per_day
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY generic_name, total_drug_cost, total_cost_per_day
ORDER BY total_cost_per_day DESC
LIMIT 10;

--V4
select d.generic_name, round(sum(total_drug_cost) / sum(total_day_supply), 2)::money as total_cost_per_day
from prescription
inner join drug d on prescription.drug_name = d.drug_name
group by d.generic_name
order by total_cost_per_day desc
limit 1 


--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' 
--which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs 
--which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
CASE
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug
LIMIT 15;

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(prescription.total_drug_cost) AS total_cost, drug_classification.drug_type
FROM prescription
INNER JOIN(
           SELECT drug_name,
		   CASE
				WHEN opioid_drug_flag = 'Y' THEN 'opioid'
				WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
				ELSE 'neither'
			END AS drug_type
			FROM drug) AS drug_classification
USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC
LIMIT 50;

select drug_name, COUNT(distinct opioid_drug_flag)
from drug
Group by drug_name
ORDER By COUNT(distinct opioid_drug_flag) DESC;


--5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
-- 10
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN'


--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsa, SUM(population)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
INNER JOIN population
USING(fipscounty)
GROUP BY cbsa
ORDER BY SUM(population) DESC
LIMIT 5;

-- The least and the greatest cbsca in one query
select *
	from (select cbsa.cbsa, sum(population) total_population
	from cbsa
	inner join population p on cbsa.fipscounty = p.fipscounty
	group by cbsa.cbsa
	order by total_population desc
	limit 1) sq1
union
select *
	from (select cbsa.cbsa, sum(population) total_population
	from cbsa
	inner join population p on cbsa.fipscounty = p.fipscounty
	group by cbsa.cbsa
	order by total_population asc
	limit 1) sq1 

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.


SELECT county, population
FROM fips_county
INNER JOIN population
USING(fipscounty)
WHERE county NOT IN
(SELECT county 
 FROM fips_county
 INNER JOIN cbsa
 USING(fipscounty)
)
ORDER BY population DESC
LIMIT 5;

SELECT county, p.population FROM fips_county f 
JOIN population p ON f.fipscounty = p.fipscounty 
LEFT JOIN cbsa c ON f.fipscounty = c.fipscounty 
WHERE f.state = 'TN' AND c.cbsa IS NULL ORDER BY 2 DESC LIMIT 1 ; 




--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT *
FROM prescription
GROUP By drug_name
WHERE total_claim_count >= 3000
ORDER BY total_claim_count

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count, opioid_drug_flag 
FROM drug
LEFT JOIN prescription
USING (drug_name)
WHERE total_claim_count >= 3000
AND opioid_drug_flag = 'Y'

--6c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT drug_name, total_claim_count, opioid_drug_flag 
FROM drug
LEFT JOIN prescription
USING (drug_name)
WHERE total_claim_count >= 3000
AND opioid_drug_flag = 'Y'

--7a. list of pain management specialists in Nashville and the # of claims for each opioid.
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y' 

--7b
--COALESCE(SUM(p2.total_claim_count), 0) 
SELECT npi, drug_name, COALESCE(SUM(total_claim_count),0)
FROM prescriber
CROSS JOIN drug
INNER JOIN prescription
      USING(npi, drug_name)
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y' 
GROUP BY npi, drug_name
ORDER BY SUM(total_claim_count);





