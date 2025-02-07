--Find info about duplicate drugs, per README
SELECT * FROM drug
WHERE drug_name IN (SELECT drug_name AS count_drug_name FROM drug GROUP BY drug_name HAVING COUNT(drug_name) > 1);

SELECT drug_name, COUNT(drug_name) AS count_drug_name FROM drug GROUP BY drug_name ORDER BY count_drug_name DESC;
SELECT drug_name, antibiotic_drug_flag, COUNT(drug_name) AS count_drug_name FROM drug GROUP BY drug_name, antibiotic_drug_flag ORDER BY count_drug_name DESC;
SELECT COUNT (DISTINCT drug_name) FROM drug;
SELECT * FROM drug;

--looking at antibiotics...
SELECT
	drug_name
	, COUNT(drug_name) AS count_drug_name
	, MAX(antibiotic_drug_flag) AS max_flag
	, MIN(antibiotic_drug_flag) AS min_flag
	, (MAX(antibiotic_drug_flag) = MIN(antibiotic_drug_flag)) AS equals_flag
FROM drug
GROUP BY drug_name
ORDER BY equals_flag, count_drug_name DESC;

/* start of q1
1.
    a. Which prescriber had the highest total number of claims (totaled over all drugs)?
	Report the npi and the total number of claims.

    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
	specialty_description, and the total number of claims.
*/

--answer 1a
--answer: npi 1881634483 with 99707
SELECT
	npi
	, SUM(total_claim_count) AS total_number_of_claims
FROM prescription
GROUP BY npi
ORDER BY total_number_of_claims DESC limit 1;

--double-check:
SELECT npi, total_claim_count, * FROM prescription WHERE npi = 1881634483 ORDER BY total_claim_count DESC;
	
SELECT * FROM prescription ORDER BY npi LIMIT 10;
SELECT * FROM prescription LIMIT 10;

--answer 1b
--answer: BRUCE PENDLEY, Family Practice with 99707 claims
SELECT
	MIN(nppes_provider_first_name) AS provider_first_name
	, MIN(nppes_provider_last_org_name) AS provider_last_org_name
	, MIN(specialty_description) AS specialty
	, SUM(total_claim_count) AS total_number_of_claims
FROM prescription
INNER JOIN prescriber USING(npi)
GROUP BY npi
ORDER BY total_number_of_claims DESC limit 1;

--double-check
SELECT
	MIN(nppes_provider_first_name) AS provider_first_name
	, MIN(nppes_provider_last_org_name) AS provider_last_org_name
	, MIN(specialty_description) AS specialty
	, MAX(nppes_provider_first_name) AS provider_first_name_check
	, MAX(nppes_provider_last_org_name) AS provider_last_org_name_check
	, MAX(specialty_description) AS specialty_check
	, SUM(total_claim_count) AS total_number_of_claims
FROM prescription
INNER JOIN prescriber USING(npi)
GROUP BY npi
ORDER BY total_number_of_claims DESC limit 10;

--verify no dupes in provider
SELECT npi FROM prescriber;				--25050
SELECT DISTINCT npi FROM prescriber; 	--25050 as well

--end of q1








/* start of q2
2.
    a. Which specialty had the most total number of claims (totaled over all drugs)?

    b. Which specialty had the most total number of claims for opioids?

    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
*/

--    a. Which specialty had the most total number of claims (totaled over all drugs)?
--    answer 2a: Familty Practice with 9,752,347 total claims
SELECT
	specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 10
;

--    b. Which specialty had the most total number of claims for opioids?
--	answer 2b: Nurse Practitioner at 900,845
SELECT
	specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber USING(npi)
WHERE drug_name IN (SELECT drug_name FROM drug GROUP BY drug_name HAVING MAX(opioid_drug_flag) = 'Y')
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 10
;

--Mike
SELECT
	specialty_description,
	SUM(total_claim_count) AS num_of_opioid_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE drug_name IN 
	(SELECT DISTINCT drug_name
	FROM drug
	WHERE opioid_drug_flag = 'Y') --this is the subquery taking distinct drug names from the drug table (not duplicates)
GROUP BY specialty_description
ORDER BY num_of_opioid_claims desc

--Karolina
SELECT SUM(total_claim_count) AS total_claim_count, specialty_description
FROM prescription AS pn LEFT JOIN prescriber AS pr ON pn.npi = pr.npi
LEFT JOIN drug ON pn.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claim_count DESC;

--My opioid subquery is (91 drugs):
SELECT drug_name FROM drug GROUP BY drug_name HAVING MAX(opioid_drug_flag) = 'Y';

SELECT DISTINCT drug_name FROM drug WHERE opioid_drug_flag = 'Y';

--start by looking at drugs, check if there are any Y AND N for a drug.
--There are 5 drugs that are listed as both Y and N!  DEMEROL is one.
--So I'll make a subquery that returns any opioids as Y
SELECT drug_name FROM drug GROUP BY drug_name HAVING MAX(opioid_drug_flag) = 'Y';

SELECT drug_name, MAX(opioid_drug_flag), MIN(opioid_drug_flag), (CASE WHEN MAX(opioid_drug_flag) = MIN(opioid_drug_flag) THEN 'same' ELSE 'different' END) AS max_min_same FROM drug
WHERE drug_name IN (SELECT drug_name AS count_drug_name FROM drug GROUP BY drug_name HAVING COUNT(drug_name) > 1)
GROUP BY drug_name
ORDER BY max_min_same;

SELECT * FROM drug WHERE drug_name = 'MEPERIDINE HCL';
SELECT * FROM drug WHERE drug_name = 'HYDROMORPHONE HCL';
SELECT * FROM drug WHERE drug_name = 'FENTANYL CITRATE';
SELECT * FROM drug WHERE drug_name = 'DEMEROL';
SELECT * FROM prescription WHERE drug_name = 'MEPERIDINE HCL'; 
SELECT * FROM prescription WHERE drug_name = 'MEPERIDINE HCL/PF'; 
SELECT * FROM drug WHERE drug_name = 'MORPHINE SULFATE';
SELECT * FROM prescription WHERE drug_name = 'MORPHINE SULFATE'; 
SELECT * FROM prescription WHERE drug_name = 'MORPHINE SULFATE/PF'; 

--Next, look at drugs used... are they all accounted for in the drug_name?  Do they ever use generic_name?
--make unions to compare drug_name
SELECT DISTINCT drug_name FROM prescription;	--1821
SELECT DISTINCT drug_name FROM drug;			--3253
SELECT DISTINCT generic_name FROM drug;		--3253
SELECT * FROM prescription LIMIT 20;
SELECT * FROM drug LIMIT 20;

SELECT drug_name FROM prescription EXCEPT SELECT drug_name FROM drug; --so all drugs in prescription are accounted for

SELECT * FROM drug
WHERE drug_name IN (SELECT drug_name AS count_drug_name FROM drug GROUP BY drug_name HAVING COUNT(drug_name) > 1);

--wrong
SELECT * FROM drug;
SELECT
	specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber USING(npi)
INNER JOIN drug USING(drug_name)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 10
;

--data exploration
SELECT DISTINCT npi FROM prescriber EXCEPT SELECT DISTINCT npi FROM prescription; -- 4458 prescribers have no related values in prescription
SELECT DISTINCT npi FROM prescription EXCEPT SELECT DISTINCT npi FROM prescriber; -- every prescription has a valid prescriber
SELECT specialty_description, COUNT(specialty_description) AS total_count FROM prescriber GROUP BY specialty_description;
SELECT * FROM prescriber LIMIT 10;
SELECT * FROM prescription LIMIT 10;
SELECT SUM(total_claim_count) AS total_claims FROM prescription;


/*
c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated
prescriptions in the prescription table?
*/

--answer 2c: 15 rows
SELECT DISTINCT specialty_description FROM prescriber
EXCEPT 
	SELECT DISTINCT specialty_description
	FROM prescriber
	LEFT JOIN prescription USING(npi)
	WHERE drug_name IS NOT NULL;

--alternative:
SELECT specialty_description
FROM prescriber AS p1
LEFT JOIN prescription AS p2 ON p1.npi = p2.npi
GROUP BY specialty_description
HAVING MIN(p2.npi) IS NULL
ORDER BY specialty_description;

SELECT *
FROM prescriber AS p1
LEFT JOIN prescription AS p2 ON p1.npi = p2.npi
WHERE specialty_description = 'Cardiac Surgery'
ORDER BY drug_name DESC
;

SELECT * FROM prescription LIMIT 10;

--Find the ones with prescriptions
SELECT DISTINCT specialty_description
FROM prescriber
LEFT JOIN prescription USING(npi)
WHERE drug_name IS NOT NULL;

SELECT * FROM prescriber LIMIT 10;
SELECT * FROM prescription LIMIT 10;

/*
	d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty,
	report the percentage of total claims by that specialty which are for opioids. Which specialties have a high
	percentage of opioids?
*/
--answer 2d:
SELECT
	specialty_description
	, ROUND((SUM(CASE WHEN opioid_flag = 'Y' THEN total_claim_count END) / SUM(total_claim_count))*100,3) AS percentage_of_claims_that_are_opioids	
	, SUM(CASE WHEN opioid_flag = 'Y' THEN total_claim_count END) AS total_claims_opioids
	, SUM(CASE WHEN opioid_flag = 'N' THEN total_claim_count END) AS total_claims_non_opioids
	, SUM(total_claim_count)
FROM prescription
INNER JOIN (SELECT drug_name, MAX(opioid_drug_flag) AS opioid_flag FROM drug GROUP BY drug_name) USING (drug_name)
INNER JOIN prescriber USING(npi)
GROUP BY specialty_description
ORDER BY percentage_of_claims_that_are_opioids DESC NULLS LAST
--ORDER BY specialty_description
;


SELECT COUNT(*) FROM prescription;
--Mike code
SELECT 
    specialty_description, 
    (CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count ELSE 0 END) AS opioid_claims,
    (total_claim_count) AS total_specialty_claims
    --(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count ELSE 0 END) * 100.0) / 
    --    SUM(total_claim_count) AS opioid_claims_percent
FROM prescription AS p1
INNER JOIN drug AS d USING (drug_name)  
INNER JOIN prescriber AS p2 ON p1.npi = p2.npi
--GROUP BY specialty_description
--ORDER BY opioid_claims_percent DESC;


--Prianka compare....
SELECT
	specialty_description
--	, ROUND((SUM(CASE WHEN opioid_flag = 'Y' THEN total_claim_count END) / SUM(total_claim_count))*100,3) AS percentage_of_claims_that_are_opioids	
	, (CASE WHEN opioid_flag = 'Y' THEN total_claim_count END) AS total_claims_opioids
	, (CASE WHEN opioid_flag = 'N' THEN total_claim_count END) AS total_claims_non_opioids
	, (total_claim_count)
FROM prescription
INNER JOIN (SELECT drug_name, MAX(opioid_drug_flag) AS opioid_flag FROM drug GROUP BY drug_name) USING (drug_name)
INNER JOIN prescriber USING(npi)
--GROUP BY specialty_description
--ORDER BY percentage_of_claims_that_are_opioids DESC NULLS LAST
--ORDER BY specialty_description
;

--goal:
--		specialty		percentage_of_claims_that_are_opioids		total_claims_for_opioids	total_claims_not_opioids

--step 1 - prescription, opioid or not.		opioid_drug_flag is Y or N
SELECT drug_name, MAX(opioid_drug_flag) AS opioid_flag FROM drug GROUP BY drug_name;
--step 2 - connect to prescription table
SELECT
	opioid_flag
	, total_claim_count
	, npi
	, drug_name
FROM prescription
INNER JOIN (SELECT drug_name, MAX(opioid_drug_flag) AS opioid_flag FROM drug GROUP BY drug_name) USING (drug_name)
;

SELECT * FROM prescription LIMIT 10;
SELECT COUNT(*) FROM prescription;			-- prescription has 656058 rows!!!
--step 3 - connect to specialties from prescriber
SELECT
	opioid_flag
	, total_claim_count
	, specialty_description
	, npi
	, drug_name
FROM prescription
INNER JOIN (SELECT drug_name, MAX(opioid_drug_flag) AS opioid_flag FROM drug GROUP BY drug_name) USING (drug_name)
INNER JOIN prescriber USING(npi)
;

SELECT * FROM prescriber LIMIT 10;

--		specialty		percentage_of_claims_that_are_opioids		total_claims_for_opioids	total_claims_not_opioids
SELECT
	specialty_description
	, ROUND((SUM(CASE WHEN opioid_flag = 'Y' THEN total_claim_count END) / SUM(total_claim_count))*100,3) AS percentage_of_claims_that_are_opioids	
	, SUM(CASE WHEN opioid_flag = 'Y' THEN total_claim_count END) AS total_claims_opioids
	, SUM(CASE WHEN opioid_flag = 'N' THEN total_claim_count END) AS total_claims_non_opioids
	, SUM(total_claim_count)
--	, opioid_flag
--	, npi
--	, drug_name
FROM prescription
INNER JOIN (SELECT drug_name, MAX(opioid_drug_flag) AS opioid_flag FROM drug GROUP BY drug_name) USING (drug_name)
INNER JOIN prescriber USING(npi)
GROUP BY specialty_description
;

SELECT
	specialty_description
--	, (SUM(CASE WHEN opioid_flag = 'Y' THEN total_claim_count END) / SUM(CASE WHEN opioid_flag = 'N' THEN total_claim_count END)) AS percentage_of_claims_that_are_opioids	
	, CASE WHEN opioid_flag = 'Y' THEN total_claim_count END AS total_claims_opioids
	, CASE WHEN opioid_flag = 'N' THEN total_claim_count END AS total_claims_non_opioids
	, total_claim_count
--	, opioid_flag
--	, npi
--	, drug_name
FROM prescription
INNER JOIN (SELECT drug_name, MAX(opioid_drug_flag) AS opioid_flag FROM drug GROUP BY drug_name) USING (drug_name)
INNER JOIN prescriber USING(npi)
--GROUP BY specialty_description
;

SELECT
	specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber USING(npi)
WHERE drug_name IN (SELECT drug_name FROM drug GROUP BY drug_name HAVING MAX(opioid_drug_flag) = 'Y')
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 10
;

SELECT * FROM prescriber LIMIT 10;
SELECT * FROM prescription LIMIT 10;

-- end of question 2













/* start of q3
3.
    a. Which drug (generic_name) had the highest total drug cost?

    b. Which drug (generic_name) has the hightest total cost per day?
	**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
*/

--a. Which drug (generic_name) had the highest total drug cost?
--answer 1a: Pirfenidone at 2,829,174.3

SELECT
	generic_name
	, total_drug_cost
FROM prescription
INNER JOIN drug USING(drug_name)
WHERE total_drug_cost = (SELECT MAX(total_drug_cost) AS highest_total_drug_cost FROM prescription)
;

--sanity checks to make sure I'm on the right path.....
SELECT * FROM drug WHERE drug_name = 'ESBRIET' LIMIT 20;
SELECT * FROM prescription ORDER BY total_drug_cost DESC LIMIT 20;

SELECT MAX(total_drug_cost) AS highest_total_drug_cost FROM prescription;

SELECT drug_name, MAX(total_drug_cost) AS highest_total_drug_cost FROM prescription GROUP BY drug_name;

SELECT * FROM drug LIMIT 20;
SELECT * FROM prescription LIMIT 20;

--    b. Which drug (generic_name) has the hightest total cost per day?
--	**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
--ANSWER 3b: IMMUN GLOB G @ 7141.11/day
SELECT
	generic_name
	, ROUND((total_drug_cost / total_day_supply),2) AS total_cost_per_day
FROM prescription
INNER JOIN drug USING(drug_name)
WHERE (total_drug_cost / total_day_supply) = (SELECT MAX(total_drug_cost / total_day_supply) FROM prescription)
;


--end of question 3













/* start of q4
4.
    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid'
	for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y',
	and says 'neither' for all other drugs.
	**Hint:** You may want to use a CASE expression for this.
	See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids
	or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
*/
--answer 4a
SELECT
	drug_name
	, (CASE WHEN MAX(opioid_drug_flag) = 'Y' THEN 'opioid' WHEN MAX(antibiotic_drug_flag) = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug
GROUP BY drug_name
; -- 3253 rows (trying to remove the duplicate drugs)

SELECT
	drug_name
	, MAX(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug
WHERE drug_name = 'DEMEROL'
GROUP BY drug_name
; -- 3253 rows (trying to remove the duplicate drugs)

SELECT
	drug_name
	, (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug
GROUP BY drug_name, drug_type
; -- 3260 rows (trying to remove the duplicate drugs)

SELECT
	drug_name
	, (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug; -- 3425 rows

SELECT
	DISTINCT drug_name
	, (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug
WHERE drug_name = 'DEMEROL'; -- 3260 rows

WITH drugs AS (
		SELECT
			DISTINCT drug_name
			, (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
		FROM drug -- 3260 rows
		)
SELECT drug_name, COUNT(drug_name) AS count_drug_name FROM drugs GROUP BY drug_name ORDER BY count_drug_name DESC;

SELECT * FROM drug LIMIT 10;

    --b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids
	--or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
--answer 4b: 105 million on opioids vs 34 million on antibiotics
WITH drugs AS (
		SELECT
			drug_name
			, (CASE WHEN MAX(opioid_drug_flag) = 'Y' THEN 'opioid'
					WHEN MAX(antibiotic_drug_flag) = 'Y' THEN 'antibiotic'
					ELSE 'neither' END)
				AS drug_type
		FROM drug
		GROUP BY drug_name
		)
--
SELECT
	SUM(CASE WHEN drug_type = 'opioid' THEN total_drug_cost END)::money AS total_spent_on_opioids
	, SUM(CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost END)::money AS total_spent_on_antibiotics
FROM prescription
INNER JOIN drugs USING (drug_name)
;

--previous answer
WITH drugs AS (
		SELECT
			drug_name
			, (CASE WHEN MAX(opioid_drug_flag) = 'Y' THEN 'opioid' WHEN MAX(antibiotic_drug_flag) = 'Y' THEN 'antibiotic' ELSE 'neither' END)
					AS drug_type
		FROM drug
		GROUP BY drug_name
		)
--
SELECT
	SUM(CASE WHEN drug_type = 'opioid' THEN total_drug_cost END)::money AS total_spent_on_opioids
	, SUM(CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost END)::money AS total_spent_on_antibiotics
FROM prescription
INNER JOIN drugs USING (drug_name)
;

SELECT SUM(total_drug_cost) AS sum_total_drug_cost
FROM prescription LIMIT 10;
SELECT * FROM prescription LIMIT 10;

--check this:
WITH drugs AS (
		SELECT
			drug_name
			, (CASE WHEN MAX(opioid_drug_flag) = 'Y' THEN 'opioid' WHEN MAX(antibiotic_drug_flag) = 'Y' THEN 'antibiotic' ELSE 'neither' END)
					AS drug_type
		FROM drug
		GROUP BY drug_name
		)
--
SELECT
	SUM(CASE WHEN drug_type = 'opioid' THEN total_drug_cost END)::money AS total_spent_on_opioids
	, COUNT(CASE WHEN drug_type = 'opioid' THEN total_drug_cost END) AS count_opioids
	, SUM(CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost END)::money AS total_spent_on_antibiotics
	, COUNT(CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost END) AS count_antibiotics
	, SUM(CASE WHEN drug_type = 'neither' THEN total_drug_cost END)::money AS total_spent_on_other
	, COUNT(CASE WHEN drug_type = 'neither' THEN total_drug_cost END) AS count_other
FROM prescription
INNER JOIN drugs USING (drug_name)
;

SELECT SUM(total_drug_cost) AS sum_total_drug_cost
FROM prescription LIMIT 10;
SELECT * FROM prescription LIMIT 10;


WITH drugs AS (
		SELECT
			drug_name
			, (CASE WHEN MAX(opioid_drug_flag) = 'Y' THEN 'opioid'
					 WHEN MAX(antibiotic_drug_flag) = 'Y' THEN 'antibiotic'
					 ELSE 'neither' END)
					AS drug_type
		FROM drug
		GROUP BY drug_name
		)
--
SELECT
	(CASE WHEN drug_type = 'opioid' THEN total_drug_cost END)::money AS total_spent_on_opioids
	, (CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost END)::money AS total_spent_on_antibiotics
FROM prescription
INNER JOIN drugs USING (drug_name)
;

SELECT COUNT(*) FROM prescription; --mine matches the record count


--Mike's
WITH drug_type_table AS (
    SELECT drug_name,
        CASE 
            WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
            ELSE 'neither'
        END AS drug_type
    FROM drug
)
SELECT 
    dt.drug_type,
    SUM(p1.total_drug_cost)::money AS total_spent
FROM prescription AS p1
INNER JOIN drug_type_table dt ON p1.drug_name = dt.drug_name ------CLEAN THIS UP
WHERE dt.drug_type IN ('opioid', 'antibiotic')
GROUP BY dt.drug_type
ORDER BY total_spent DESC;

--Mike count
WITH drug_type_table AS (
    SELECT drug_name,
        CASE 
            WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
            ELSE 'neither'
        END AS drug_type
    FROM drug
)
SELECT 
    dt.drug_type,
    SUM(p1.total_drug_cost)::money AS total_spent,				--31932 opioid, 46388 antibiotic, 626695 neither for Mike
	COUNT(p1.total_drug_cost) AS count_of						--vs 31932		43768				580358		for me
FROM prescription AS p1
INNER JOIN drug_type_table dt ON p1.drug_name = dt.drug_name ------CLEAN THIS UP
WHERE dt.drug_type IN ('opioid', 'antibiotic','neither')
GROUP BY dt.drug_type
ORDER BY total_spent DESC;


--end of q4













/* start of q5
5.
    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states,
	not just Tennessee.

    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

    c. What is the largest (in terms of population) county which is not included in a CBSA?
	Report the county name and population.
	*/
/*
    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states,
	not just Tennessee.
*/
--answer 5a: 10 CBSAs are in TN.  10 distinct cbsanames.
SELECT DISTINCT cbsa, cbsaname FROM cbsa WHERE cbsaname LIKE '%TN%';

SELECT * FROM cbsa WHERE cbsaname LIKE '%TN%';
SELECT COUNT(*) FROM cbsa; --	1238 rows
SELECT * FROM cbsa;


--    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--Answer 5b
SELECT
	cbsaname
	, SUM(population) AS combined_population
FROM cbsa
INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY combined_population DESC;

SELECT * FROM population WHERE fipscounty = '47001' OR fipscounty = '47009';
SELECT * FROM population;

/*
    c. What is the largest (in terms of population) county which is not included in a CBSA?
	Report the county name and population.
	*/
--answer 5c: Sevier County, with population of 95,523
SELECT *
FROM population
INNER JOIN fips_county USING (fipscounty)
WHERE fipscounty IN (SELECT fipscounty FROM population EXCEPT SELECT DISTINCT fipscounty FROM cbsa)
ORDER BY population DESC
;

--53 rows where they are not in a CBSA
SELECT *
FROM population
WHERE fipscounty IN (SELECT fipscounty FROM population EXCEPT SELECT DISTINCT fipscounty FROM cbsa)
ORDER BY population DESC
;

SELECT * FROM population WHERE fipscounty = '47155';
SELECT * FROM cbsa WHERE fipscounty = '47155';
SELECT * FROM fips_county WHERE fipscounty = '47155';
--end of q5












/* start of q6
6.
    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the
	total_claim_count.

    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

    c. Add another column to you answer from the previous part which gives the prescriber first and last name
	associated with each row.
*/
--    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the
--	total_claim_count.
--	I AM CONFUSED BY THIS ONE, WHAT IS MEANT BY total_claims ?  I WILL GO BY total_claim_count FOR NOW UNTIL I ASK FOR
--	CLARIFICATION OR FIGURE IT OUT BASED ON THE NEXT PARTS OF THE QUESTION.
-- answer 6a:
SELECT
	drug_name
	, total_claim_count
--	, *
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC
;

--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
--answer 6b:
WITH opioid_cte AS (		--cte to display drugs only once.  For ones that are opioids and listed as Y and N, it will be Y.
			    SELECT drug_name,
			        MAX(opioid_drug_flag) AS opioid_flag
			    FROM drug
				GROUP BY drug_name
)
SELECT
	drug_name
	, total_claim_count
	, opioid_flag
FROM prescription
INNER JOIN opioid_cte USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC
;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last name
--	associated with each row.
--answer 6c
WITH opioid_cte AS (		--cte to display drugs only once.  For ones that are opioids and listed as Y and N, it will be Y.
			    SELECT drug_name,
			        MAX(opioid_drug_flag) AS opioid_flag
			    FROM drug
				GROUP BY drug_name
)
SELECT
	drug_name
	, total_claim_count
	, opioid_flag
	, nppes_provider_last_org_name
	, nppes_provider_first_name
FROM prescription
INNER JOIN opioid_cte USING(drug_name)
INNER JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC
;

SELECT * FROM prescription LIMIT 10;
--end of q6












/* start of q7
7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number
of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

    a. First, create a list of all npi/drug_name combinations for pain management specialists
	(specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
	where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it.
	You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not
	the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google
	the COALESCE function.
*/

--just messing around.....
SELECT * FROM prescriber WHERE specialty_description ILIKE '%pain%';
SELECT * FROM prescriber WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description ILIKE '%Pain Management%';
SELECT * FROM prescriber LIMIT 10;

/*
	a. First, create a list of all npi/drug_name combinations for pain management specialists
	(specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
	where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it.
	You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
*/
--answer 7a:
WITH opioid_cte AS (		--cte to display drugs only once.  For ones that are opioids and listed as Y and N, it will be Y.
			    SELECT drug_name,
			        MAX(opioid_drug_flag) AS opioid_flag
			    FROM drug
				GROUP BY drug_name
)
SELECT npi, drug_name
FROM prescriber
CROSS JOIN opioid_cte
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_flag = 'Y'
;

/*
    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not
	the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count). */
--answer 7b
WITH opioid_cte AS (		--cte to display drugs only once.  For ones that are opioids and listed as Y and N, it will be Y.
			    SELECT drug_name,
			        MAX(opioid_drug_flag) AS opioid_flag
			    FROM drug
				GROUP BY drug_name
)
SELECT npi, drug_name, total_claim_count
FROM prescriber
CROSS JOIN opioid_cte
LEFT JOIN prescription USING(npi,drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_flag = 'Y'
;

/*
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google
	the COALESCE function.  */
--answer 7c:
WITH opioid_cte AS (		--cte to display drugs only once.  For ones that are opioids and listed as Y and N, it will be Y.
			    SELECT drug_name,
			        MAX(opioid_drug_flag) AS opioid_flag
			    FROM drug
				GROUP BY drug_name
)
SELECT npi, drug_name, COALESCE(total_claim_count, 0) AS total_claims
FROM prescriber
CROSS JOIN opioid_cte
LEFT JOIN prescription USING(npi,drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_flag = 'Y'
ORDER BY total_claims DESC
;

--end of q7