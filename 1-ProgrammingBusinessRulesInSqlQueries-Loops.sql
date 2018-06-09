--------------------------------------------------------------------------------------------------------
-- THIS WORK IS LICENSED  Original Author : Maurice Pelchat UNDER CREATITVE COMMONS "Attribution CC BY"
-- Original Author : Maurice Pelchat https://www.linkedin.com/in/maurice-pelchat-9891495/
-- https://creativecommons.org/licenses/by/4.0/
-- https://creativecommons.org/licenses/by/4.0/legalcode
-- This license lets others distribute, remix, tweak, and build upon your work, even commercially, 
-- as long as YOU CREDIT ME for the original creation. 
-- This is the most accommodating of licenses offered. Recommended for maximum dissemination and use of licensed materials.
-- 
-- see https://creativecommons.org/share-your-work/licensing-types-examples/licensing-examples/
--------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- IN THIS SCRIPT I WILL OFTEN USE ROW CONSTRUCTOR TO DEFINE VIRTUAL TABLES
-- IT HELPS SEEING MORE THE DATA INTO THE QUERY, AND MAKE SCRIPT PARTS MORE REPLAYABLE
------------------------------------------------------------------------------------------------------
-- explaining row constructor: A Values clause followed by repeating or non-repeating rows
create table #demo (i int, mainLoopName nvarchar(50))
Insert into #demo 
Values (1, 'Main'), (2, 'Main'), (3, 'Main') 

select * from #demo

-- Using a row constructor wrapped in a From. We are going to use them to define virtual tables
-- Since it is a virtual table, AS Tablename(columnname, columnname, ... ) is required
Select * From (Values (1, 'Main'), (2, 'Main'), (3, 'Main')) as t (I, MainLoopName)  
Select * From (Values (4, 'Inner'), (5, 'Inner'), (6, 'Inner')) as t (J, InnerloopName)  

----------------------------------------------------------------------------------------
-- One another interesting usage of row constructor is to introduce constants in queries
-- See it later in demos
----------------------------------------------------------------------------------------
Select *
from 
  (Values ('F','M','G') ) as Constants(father, mother, gardian)
  CROSS JOIN caregivers
Where typOfCaregiver IN (father, mother)

------------------------------------------------------------------------------------------------------
-- TRANSPOSE OUR PROGRAMMING SKILLS DIRECTLY IN QUERIES
-- THE BASIS OF PROGRAMMING ARE LOOPS, VARS, CONDITIONAL LOGIC, AND MAKE PROGRAMMING PIECES REUSABLE
-- LET'S DEMO INHERENT LOOPING OF SQL, DON'T ADD LOOP TO YOUR CODE, USE INHERENT LOOPING OF SQL
------------------------------------------------------------------------------------------------------
-- create 2 demos tables MainLoop, and NestedLoop

--##LOOPS PROGRAMMING IN QUERIES, DO I NEED SOME

Select * into MainLoop From (Values (1, 'Main'), (2, 'Main'), (3, 'Main')) as t (I, MainLoopName)  
Select * into NestedLoop From (Values (4, 'Inner'), (5, 'Inner'), (6, 'Inner')) as t (J, InnerloopName)  


-- show the loop effect, by a cartesian product.  Cconceptually SQL does a main loop over a nested loop, a cartesian product
select MainLoopName, I, InnerloopName, J 
FROM MainLoop, NestedLoop Order by I, J

-- I prefer to explicitly name a join, and if there is no condition, the word "CROSS" is added to let know to SQL there is no condition for this join
Select * FROM MainLoop CROSS JOIN NestedLoop Order by I, J

--cleanup
Drop table MainLoop  
Drop table NestedLoop  

-- I COULD HAVE DONE ALSO... SO WHY BOTHER WITH REAL TABLES FOR DEMOS AND CLEANUP
Select ML.*, IL.*
From 
    (Values (1, 'Main'), (2, 'Main'), (3, 'Main')) as ML (I, MainLoopName)  
  , (Values (4, 'Inner'), (5, 'Inner'), (6, 'Inner')) as IL (J, InnerloopName)  

Select ML.*, IL.*
From 
    (Values (1, 'Main'), (2, 'Main'), (3, 'Main')) as ML (I, MainLoopName)  
    CROSS JOIN (Values (4, 'Inner'), (5, 'Inner'), (6, 'Inner')) as IL (J, InnerloopName)  

-----------------------------------------------------------------------------
-- looping applies to real data, but cartesian product are meaningless with
-- data that must be matched.  In the background you can have for such small
-- data sets a cartesian product in processing but the ON clause condition
-- of the join restricts the result to match this condition
-----------------------------------------------------------------------------
Select *
From 
  ( -- Loop over Students, imagine it could've been a real table
  values 
    ('Joe' , 'good', 12132)
  , ('Lu'  , 'Khin', 22323)
  , ('Hi'  , 'Bye' , 34571)
  ) Students(firstName, Lastname, Id)
  JOIN -- For each student loop students grp, imagine it could've been a real table
  (
  values 
    (12132, 'MAT123')
  , (12132, 'CHI234')
  , (22323, 'MAT123')
  , (22323, 'CHI234')
  , (22323, 'FRA345')
  , (34571, 'CHI234')
  , (34571, 'FRA345')
  ) StudentsGroups(StudentId, Grp)
  -- when looping discard non-matching studentId
  ON StudentsGroups.StudentId = Students.Id
  JOIN -- for each student group loop over results, imagine it could've been a real table
  (
  values 
    (12132, 'MAT123', 1, 80)
  , (12132, 'MAT123', 2, 85)
  , (12132, 'MAT123', 3, 77)

  , (12132, 'CHI234', 1, 80)
  , (12132, 'CHI234', 2, 85)

  , (22323, 'MAT123', 1, 65)
  , (22323, 'MAT123', 2, 79)
  , (22323, 'MAT123', 3, 91)

  , (22323, 'CHI234', 1, 88)
  , (22323, 'CHI234', 2, 74)

  , (22323, 'FRA345', 1, 88)
  , (22323, 'FRA345', 2, 74)

  , (34571, 'CHI234', 1, 47)
  , (34571, 'CHI234', 2, 74)

  , (34571, 'FRA345', 1, 99)
  , (34571, 'FRA345', 2, 71)
  ) StudentsGroupsResults(StudentId, Grp, Step, Grade)
  -- when looping discard non-matching studentId-Grp
  ON StudentsGroupsResults.StudentId = StudentsGroups.StudentId And StudentsGroupsResults.Grp = StudentsGroups.Grp


-- CONCLUSION : IF YOU NEED TO FIGURE OUT A LOOP IN YOUR BUSINESS LOGIC, FIGURE OUT
-- FIRST THAT THERE IS BIG RISKS THAT SQL IS GOING TO DO IT FOR YOU.
-- DON'T TRY TO PROGRAM IT

-- ONE EXCEPTION: I WANT TO FIND LAST FRIDAY OF THE MONTH OF A GIVEN DATE
-- I'LL DO IT THE LAZY WAY, WITH A LOOP, NO MATHS PLEASE...

-- SOLVING THE PROBLEM WITH LAME DISPOSITION

Select *, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate())), Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate())))
From (values (0),(1),(2),(3),(4),(5),(6)) as loopIndex(numberOfDayToSubstract)
Where Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))) = 'FRIDAY'

-- MAKE IT BETTER PLEASE
Select -- show the loop only
  *
, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
, Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate())))
From (values (0),(1),(2),(3),(4),(5),(6)) as loopIndex(numberOfDayToSubstract)

Select -- show the loop and logic, here WHERE participates in logic
  *
, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
, Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate())))
From (values (0),(1),(2),(3),(4),(5),(6)) as loopIndex(numberOfDayToSubstract)
Where Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))) = 'FRIDAY'

Select Top 1 -- show the loop and logic, here WHERE participates in logic, and TOP 1 stops searching when first row is found (optimize the lazy)
  *
, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
, Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate())))
From (values (0),(1),(2),(3),(4),(5),(6)) as loopIndex(numberOfDayToSubstract)
Where Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))) = 'FRIDAY'

-- FINDING LAST FRIDAY OF THIS MONTH WITH THIS PROGRAMMING STYLE IS LAME...
-- NOT BECAUSE OF THE LAZINESS OF USING A LOOP
-- BUT BECAUSE OF THE ABUSE OF ANNONYMOUS EXPRESSIONS REPEATS
-- LET'S LOOK TO THE VALUE OF APPLY CLAUSE TO MAKE IT CLEAN AND READABLE

