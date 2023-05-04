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
| bigquery-public-data.chicago_crime.crime.primary_type=crimes_ds.chicago_iucr_ref.	
PRIMARY_DESCRIPTION``` for the matching IUCR code | 
| bigquery-public-data.chicago_crime.crime.description=crimes_ds.chicago_iucr_ref.	
SECONDARY_DESCRIPTION``` for the matching IUCR code | 




### 4. Identify if there are IUCR code/description discrepancies/mismatches across tables

There are discrepancies and this query catches them-
```
select ct.unique_key, ct.iucr as iucr_ct, rd.iucr as iucr_rd, ct. 
from bigquery-public-data.chicago_crime.crime ct
left outer join crimes_ds.chicago_iucr_ref rd
on (ct.iucr=rd.iucr)
where rd.iucr is null
```

There are codes in the crimes table that are not in the IUCR codes table.

Lets do a comparison on the crimes table description







