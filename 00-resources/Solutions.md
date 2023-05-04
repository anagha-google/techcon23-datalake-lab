# Solutions for Challenge Lab

### 3. Analyze the relationship between the two tables and how they can be joined

From a quick visual, the column that the transactional crimes data and the reference IUCR codes data can be joined on is the IUCR codes. Lets study the IUCR codes across tables for code 0470-

<br>Lets look at the crimes transactional data-
```
select * from bigquery-public-data.chicago_crime.crime where iucr='0470' LIMIT 2
```

And then, the reference data-
```
select * from crimes_ds.chicago_iucr_ref where iucr='0470'
```

Here is how the data across the tables can be matched.

| Matches | 
| -- |
| ```bigquery-public-data.chicago_crime.crime.iucr=crimes_ds.chicago_iucr_ref.iucr``` | 
| ```bigquery-public-data.chicago_crime.crime.primary_type=crimes_ds.chicago_iucr_ref.PRIMARY_DESCRIPTION``` for the matching IUCR code | 
| ```bigquery-public-data.chicago_crime.crime.description=crimes_ds.chicago_iucr_ref.SECONDARY_DESCRIPTION``` for the matching IUCR code | 




### 4. Identify if there are IUCR code/description discrepancies/mismatches across tables

There are discrepancies and this query catches them-
```
select distinct ct.iucr as iucr_ct, rd.iucr  as iucr_rd, ct.primary_type as primary_description, ct.description as secondary_description 
from bigquery-public-data.chicago_crime.crime ct
left outer join crimes_ds.chicago_iucr_ref rd
on (ct.iucr=rd.iucr)
where rd.iucr is null
```

There are codes in the crimes (transactions) table that are not in the IUCR codes (reference data) table. <br>
Lets do a comparison based on IUCR descriptions.<br>

```
WITH IUCR_DISCREPANCIES AS(
select distinct ct.iucr as iucr_ct, rd.iucr  as iucr_rd, ct.primary_type as primary_description, ct.description as secondary_description 
from bigquery-public-data.chicago_crime.crime ct
left outer join crimes_ds.chicago_iucr_ref rd
on (ct.iucr=rd.iucr)
where rd.iucr is null)
select IUCR_DISCREPANCIES.iucr_ct as iucr_crimes, IUCR_DISCREPANCIES.primary_description, IUCR_DISCREPANCIES.secondary_description,IUCR_REF.iucr as iucr_ref_data  
from IUCR_DISCREPANCIES JOIN crimes_ds.chicago_iucr_ref IUCR_REF
ON (IUCR_DISCREPANCIES.primary_description=IUCR_REF.primary_description and IUCR_DISCREPANCIES.secondary_description=IUCR_REF.secondary_description)
```

Great! Looks like the data we have in the crimes table is good to go, and accurate. The reference data on the other hand had a few codes missing left padding with zeroes. As a data engineer, you would update the architect with your findings.

Lets proceed to the next step.

### 5. Identify missing entries in either table

Now that we know the issue, lets run a SQL with the requisite left padding to ensure no dispancies-




### 6. Create a crime trend report set with crimes by type, by year, month, week, day, hour



