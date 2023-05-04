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

iucr column is a match.



