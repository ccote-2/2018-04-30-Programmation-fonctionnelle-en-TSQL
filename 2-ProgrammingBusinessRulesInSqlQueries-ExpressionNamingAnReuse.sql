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
-- TRANSPOSE OUR PROGRAMMING SKILLS DIRECTLY IN QUERIES
-- THE BASIS OF PROGRAMMING ARE LOOPS, VARS, CONDITIONAL LOGIC, AND MAKE PROGRAMMING PIECES REUSABLE
-- LET'S DEMO VARS FROM A PREVIOUS LOOP DEMOS SAMPLE
------------------------------------------------------------------------------------------------------

-- I WANT TO FIND LAST FRIDAY OF THE MONTH OF A GIVEN DATE
-- I'LL DO IT THE LAZY WAY, WITH A LOOP, NO MATHS PLEASE...

Select Top 1 -- show the loop and logic, here WHERE participates in logic, and TOP 1 stops searching when first row is found (optimize the lazy)
  *
, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
, Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate())))
From (values (0),(1),(2),(3),(4),(5),(6)) as loopIndex(numberOfDayToSubstract)
Where Datename(dw, dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))) = 'FRIDAY'

-- FINDING LAST FRIDAY OF THIS MONTH WITH THIS PROGRAMMING STYLE IS LAME...
-- NOT BECAUSE OF THE LAZINESS OF USING A LOOP INSTEAD OF FANCY MATHs
-- BUT BECAUSE OF THE ABUSE OF ANNONYMOUS EXPRESSIONS REPEATS
-- LET'S LOOK TO THE VALUE OF APPLY CLAUSE TO MAKE IT CLEAN AND READABLE

-- MY OLD BRAIN DISLIKE NESTED ANONYMOUS EXPRESSION
-- LET'S TRY TO IMPROVE READABILITY AND MEANING IN QUERY BY USING CROSS APPLY CLAUSE
-- CROSS HAS THE MEANING OF CROSS AS IN CROSS JOIN
-- SO FIRST LET'S CONCENTRATE ON APPLY
-- APPLY SAYS : IN THIS ROW APPLY A SUBQUERY EXPRESSION THAT MUST RETURN AT LEAST ONE NAMED COLUMN
-- WE ARE GOING TO EXTEND SYNTAX VERTICALLY TO BETTER UNDERSTANDBILITY

Select L.numberOfDayToSubstract, N.nthDayFromEofmonth, W.WeekDayName
From 
  (values (0),(1),(2),(3),(4),(5),(6)) as L(numberOfDayToSubstract)
  CROSS APPLY 
  (
  Select nthDayFromEofmonth=dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
  ) as N
  CROSS APPLY 
  (
  Select WeekDayName=Datename(dw, nthDayFromEofmonth)
  ) as W
Where Datename(dw, nthDayFromEofmonth) = 'FRIDAY'

-- RUN FIRST PART, GIVE A SENSE OF THE LOOP
Select L.numberOfDayToSubstract
From 
  (values (0),(1),(2),(3),(4),(5),(6)) as L(numberOfDayToSubstract)

-- RUN FIRST AND SECOND PARTS, APPLY ADDS PROCESSING AT EACH ROW
-- THIS LOOKS LIKE A TRACE OUTPUT
-- APPLY TAKE TAKING INPUT COLUMN VALUE FROM CURRENT ROW, ADD NEW COLUMN WITH ITS VALUE TO THIS ROW
Select L.numberOfDayToSubstract, N.nthDayFromEofmonth
From 
  (values (0),(1),(2),(3),(4),(5),(6)) as L(numberOfDayToSubstract)
  CROSS APPLY 
  (
  Select nthDayFromEofmonth=dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
  ) as N

-- SEE ALMOST COMPLETE QUERY
-- LAST APPLY DOES SOME PROCESSING AT EACH ROW ALSO
-- TAKING INPUT FROM CURRENT ROW, ADD ANOTHER NEW COLUMN TO THIS ROW
-- OUTPUT IS ALSO A FULL TRACE
Select L.numberOfDayToSubstract, N.nthDayFromEofmonth, W.WeekDayName
From 
  (values (0),(1),(2),(3),(4),(5),(6)) as L(numberOfDayToSubstract)
  CROSS APPLY 
  (
  Select nthDayFromEofmonth=dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
  ) as N
  CROSS APPLY 
  (
  Select WeekDayName=Datename(dw, nthDayFromEofmonth)
  ) as W

-- ADDING WHERE CLAUSE FINISH THE JOB, EVERY COLUMN CREATED BY APPLYs
-- ARE USABLE OUTSIDE OF THE FROM (IN SELECT, WHERE, GROUP BY, ORDER BY)
Select L.numberOfDayToSubstract, N.nthDayFromEofmonth, W.WeekDayName
From 
  (values (0),(1),(2),(3),(4),(5),(6)) as L(numberOfDayToSubstract)
  CROSS APPLY 
  (
  Select nthDayFromEofmonth=dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))
  ) as N
  CROSS APPLY 
  (
  Select WeekDayName=Datename(dw, nthDayFromEofmonth)
  ) as W
Where WeekDayName = 'FRIDAY'

-- NOW SYNTAX IS UNDERSTOOD WE CAN COMPRESS IT. 
-- ONE APPLY = ONE NEW COMPUTED COLUMN ADDED, ALL ON THE SAME LINE, LIKE A VARIABLE ASSIGNMENT
-- ALIASES IN THIS SELECT AREN'T NECESSARY, ALL COLUMNS NAME ARE UNIQUE.
-- WE ADD TOP (1) TO STOP SEARCH AS SOON A THE ANSWER IS FOUND
Select TOP(1) numberOfDayToSubstract, nthDayFromEofmonth, WeekDayName
From 
  (values (0),(1),(2),(3),(4),(5),(6)) as L(numberOfDayToSubstract)
  CROSS APPLY (Select nthDayFromEofmonth=dateadd(dd, -numberOfDayToSubstract, eoMonth(getdate()))) as nthDayFromEofmonth
  CROSS APPLY (Select WeekDayName=Datename(dw, nthDayFromEofmonth)) as WeekDayName
Where WeekDayName = 'FRIDAY'

-- I'M JUST DOING HERE IN SQL THAT AN EQUIVALENT OF WHAT A C# PROGRAMMER
-- WOULD'VE DONE THIS WAY

/*
//--  (Select lastDayOfMonth=eoMonth(getdate()) ) as lastDayOfMonth
var lastDayOfMonth = (new DateTime(DateTime.Today.Year, DateTime.Today.Month, 1)).AddMonths(1).AddDays(-1);
DateTime nthDayFromEofmonth;
//-- values (0),(1),(2),(3),(4),(5),(6)
int[] numbers = { 0, 1, 2, 3, 4, 5, 6 };  
//-- CROSS JOIN (values (0),(1),(2),(3),(4),(5),(6)) as loopIndex(numberOfDayToSubstract)
foreach (int numberOfDayToSubstract in numbers) 
{
    //-- CROSS APPLY(Select nthDayFromEofmonth = dateadd(dd, -loopIndex.numberOfDayToSubstract, lastDayOfMonth)) as nthDayFromEofmonth
    nthDayFromEofmonth = lastDayOfMonth.AddDays(-numberOfDayToSubstract);
    //-- CROSS APPLY(Select DayName = Datename(dw, nthDayFromEofmonth)) as DayName
    //-- Where DayName = 'FRIDAY' and top 1
    if (nthDayFromEofmonth.DayOfWeek.ToString() == "friday") { break; }; // where
}
*/
GO
-- WHY NOT MAKE THIS CODE REUSABLE, AND MORE FLEXIBLE
If Object_id('dbo.LastFridayOfMonthForAGivenDate') IS NOT NULL DROP FUNCTION dbo.LastFridayOfMonthForAGivenDate
GO
CREATE FUNCTION dbo.LastFridayOfMonthForAGivenDate(@Date AS Date)
RETURNS TABLE AS RETURN
Select TOP(1) nthDayFromEofmonth
From 
  (values (0),(1),(2),(3),(4),(5),(6)) as L(numberOfDayToSubstract)
  CROSS APPLY (Select nthDayFromEofmonth=dateadd(dd, -numberOfDayToSubstract, eoMonth(@Date))) as nthDayFromEofmonth
  CROSS APPLY (Select WeekDayName=Datename(dw, nthDayFromEofmonth)) as WeekDayName
Where WeekDayName = 'FRIDAY'
GO
Select * 
From 
  (VALUES ('20180101'), ('20180312'), ('20190707') ) As DateSet(d)
  CROSS APPLY dbo.LastFridayOfMonthForAGivenDate(d)

-- SOME OTHER EXAMPLE
-- COMPUTING POOLVOLUME IN LITERS
Select *
From 
  (Select PIValue = 3.1416, RadiusInFeet = 28/2, PoolHeightInInches = 54) as Prm
  CROSS APPLY (Select PoolHeightInCm = PoolHeightInInches * 2.54) as PoolHeightInCm
  CROSS APPLY (Select radiusInCm = RadiusInFeet * 12 * 2.54) as radiusInCm
  CROSS APPLY (Select SqrRadius = radiusInCm * radiusInCm) as SqrRadius
  CROSS APPLY (Select PoolVolumeInLiters = (PIValue * SqrRadius * PoolHeightInCm) / 1000 ) as PoolVolumeInLiters 
GO
-- MAKING THIS COMPUTATION REUSABLE
if object_id('dbo.ComputePoolVolumeInLiters') is not null drop function dbo.ComputePoolVolumeInLiters 
go
CREATE Function dbo.ComputePoolVolumeInLiters (@diameterInFeet Real, @PoolHeightInInches Real) -- name it and parameters
Returns Table AS Return 
Select *
From 
  (Select PIValue = 3.1416, diameterInFeet=@diameterInFeet, RadiusInFeet = @diameterInFeet/2, PoolHeightInInches = @PoolHeightInInches) as Prm
  CROSS APPLY (Select PoolHeightInCm = PoolHeightInInches * 2.54) as PoolHeightInCm
  CROSS APPLY (Select radiusInCm = RadiusInFeet * 12 * 2.54) as radiusInCm
  CROSS APPLY (Select SqrRadius = radiusInCm * radiusInCm) as SqrRadius
  CROSS APPLY (Select PoolVolumeInLiters = (PIValue * SqrRadius * PoolHeightInCm) / 1000 ) as PoolVolumeInLiters 
GO
-- REUSE IT : CROSS APPLY functionName And parameters (column from current row)
Select *
From 
  (Values ('Sunrise', 15, 48), ('Miami', 22, 48), ('TropicSea', 28, 54) ) as PoolProducts(name, diameter, Height)
  CROSS APPLY dbo.ComputePoolVolumeInLiters (diameter, height)
GO
-- ALTERNATE WAY : IN A SUBQUERY RESULTS CAN BE RENAMED IN CROSS APPLY (Select From Function) as Alias
Select *
From 
  (Values ('Sunrise', 15, 48), ('Miami', 22, 48), ('TropicSea', 28, 54) ) as PoolProducts(name, diameter, Height)
  CROSS APPLY (Select PoolVolumeInLiters from dbo.ComputePoolVolumeInLiters (diameter, height)) as VolInfo
GO
-- MAKE MORE GENERIC STUFF
if object_id('dbo.GeometryFromPI') is not null drop function dbo.GeometryFromPI
go
Create function dbo.GeometryFromPI (@Radius float, @Height float, @ArcAngle float)
Returns Table as Return
  Select *
  From 
    (Select PI=3.1416) as Pi
    CROSS APPLY (Select Radius=@radius) as Radius
    CROSS APPLY (Select Height=@Height) As Height
    CROSS APPLY (Select ArcAngle=@ArcAngle) as ArcAngle
    CROSS APPLY (Select Diameter=radius*2) as diameter
    CROSS APPLY (Select SqrRadius=Radius * Radius) as SqrRadius
    CROSS APPLY (Select CubicRadius=Radius * Radius * Radius) as CubicRadius
    CROSS APPLY (Select Circumference=diameter * Pi) as Circumference
    CROSS APPLY (Select circleSurface=SqrRadius * Pi) as circleSurface  
    CROSS APPLY (Select angleRatio = ArcAngle/360.0) as angleRatio 
    CROSS APPLY (Select ConeVolume=1/3.0 * circleSurface * Height) as ConeVolume 
    CROSS APPLY (Select CylinderVolume=circleSurface * Height) as CylinderVolume 
    CROSS APPLY (Select SphereVolume=4/3.0 * Pi * CubicRadius) as SphereVolume 
    CROSS APPLY (Select SphereVolumeTheOtherWay=4/3.0 * circleSurface * radius) as SphereVolumeTheOtherWay 
    CROSS APPLY (Select ArcLength=angleRatio * Circumference) as ArcLength
    CROSS APPLY (Select SectorSurface=angleRatio * circleSurface) as SectorSurface
GO
-- USE MORE GENERIC STUFF
-- UNIT TRANSLATION ARE NECESSARY
if object_id('dbo.ComputePoolVolumeInLiters') is not null drop function dbo.ComputePoolVolumeInLiters 
go
CREATE Function dbo.ComputePoolVolumeInLiters (@diameterInFeet Real, @PoolHeightInInches Real) -- name it and parameters
Returns Table AS Return 
Select * -- radiusInCm, PoolHeightInCm, CylinderVolumeInCm3=G.CylinderVolume, PoolVolumeInLiters
From 
  (Select radiusInCm = (@diameterInFeet/2) * 12 * 2.54, PoolHeightInCm = @PoolHeightInInches * 2.54) as Prm
  CROSS APPLY dbo.GeometryFromPI (radiusInCm, PoolHeightInCm, null) as G
  CROSS APPLY (Select PoolVolumeInLiters = G.CylinderVolume / 1000 ) as PoolVolumeInLiters 
GO
-- BUT WHY NOT USE SCALAR FUNCTIONS THAT REQUIRES NO CROSS APPLY TO BE USED ?
-- FIRST THEY CAN'T BE EXTENDED TO RETURN MORE THAN ONE VALUE
-- SECOND THEY ARE BLACK BOXES TO THE OPTIMIZER, IT IS AN ALL OR NOTHING PROPOSITION
-- BUT OPTIMIZER DOES MUCH BETTER JOB WITH INLINE FUNCTIONS

-- FULL DEBUG, ASK ALL COLUMNS
Select *
From 
  (Values ('Sunrise', 15, 48), ('Miami', 22, 48), ('TropicSea', 28, 54) ) as PoolProducts(name, diameter, Height)
  CROSS APPLY dbo.ComputePoolVolumeInLiters(diameter, height) as Volume

-- EXPRESSION EXTRACTED FROM ACCESS PLAN: SIZE OF TOTAL POSSIBLE COMPUTATIONS (5520 characters) 
--[Expr1012] = Scalar Operator(CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000)); [Expr1013] = Scalar Operator(CONVERT_IMPLICIT(real(24),[Union1011],0)*(2.5399999618530273e+000)); [Expr1014] = Scalar Operator((3.1416)); [Expr1015] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)); [Expr1016] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1011],0)*(2.5399999618530273e+000),0)); [Expr1017] = Scalar Operator(NULL); [Expr1018] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*(2.0000000000000000e+000)); [Expr1019] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)); [Expr1020] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)); [Expr1021] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*(2.0000000000000000e+000)*CONVERT_IMPLICIT(float(53),(3.1416),0)); [Expr1022] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),(3.1416),0)); [Expr1023] = Scalar Operator(NULL/(3.6000000000000000e+002)); [Expr1024] = Scalar Operator((3.3333299999999999e-001)*(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),(3.1416),0))*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1011],0)*(2.5399999618530273e+000),0)); [Expr1025] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),(3.1416),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1011],0)*(2.5399999618530273e+000),0)); [Expr1026] = Scalar Operator(CONVERT_IMPLICIT(float(53),(1.333333)*(3.1416),0)*(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0))); [Expr1027] = Scalar Operator((1.3333330000000001e+000)*(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),(3.1416),0))*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)); [Expr1028] = Scalar Operator(NULL/(3.6000000000000000e+002)*(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*(2.0000000000000000e+000)*CONVERT_IMPLICIT(float(53),(3.1416),0))); [Expr1029] = Scalar Operator(NULL/(3.6000000000000000e+002)*(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),(3.1416),0))); [Expr1030] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),(3.1416),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1011],0)*(2.5399999618530273e+000),0)/(1.0000000000000000e+003))

-- FULL DEBUG, ASK ONLY MEANINGFUL COLUMNS
-- ACCESS PLAN DEMONSTRATE THAT THE OPTIMIZER PEEKS INTO UNDERLYING FUNCTION TO 
-- EXTRACT NEEDED EXPRESSIONS ONLY
-- NO OVERHEAD IN FUNCTION CALLS, THIS IS LIKE A MACRO INTERPRETER
Select PoolProducts.diameter, PoolProducts.height, Volume.radiusInCm, Volume.PoolHeightInCm, Volume.PoolVolumeInLiters
From 
  (Values ('Sunrise', 15, 48), ('Miami', 22, 48), ('TropicSea', 28, 54) ) as PoolProducts(name, diameter, Height)
  CROSS APPLY dbo.ComputePoolVolumeInLiters(diameter, height) as Volume
-- EXPRESSION EXTRACTED FROM ACCESS PLAN: SIZE OF IS MUCH SHORTER, THE OPTIMIZER WEED OUT USELESS EXPRESSKON PATHS (740 characters) 
--[Expr1012] = Scalar Operator(CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000)); [Expr1013] = Scalar Operator(CONVERT_IMPLICIT(real(24),[Union1011],0)*(2.5399999618530273e+000)); [Expr1030] = Scalar Operator(CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1010],0)/(2.0000000000000000e+000)*(1.2000000000000000e+001)*(2.5399999618530273e+000),0)*CONVERT_IMPLICIT(float(53),(3.1416),0)*CONVERT_IMPLICIT(float(53),CONVERT_IMPLICIT(real(24),[Union1011],0)*(2.5399999618530273e+000),0)/(1.0000000000000000e+003))


if object_id('dbo.GeometryFromPI') is not null drop function dbo.GeometryFromPI
go
-- THE WAY dbo.GeometryFromPI IS USED IN dbo.ComputePoolVolumeInLiters IS LIKE A REWRITE
-- OF THIS FUNCTION THIS WAY
Create function dbo.GeometryFromPI (@Radius float, @Height float, @ArcAngle float)
Returns Table as Return
  Select *
  From 
    (Select PI=3.1416) as Pi
    CROSS APPLY (Select Radius=@radius) as Radius
    CROSS APPLY (Select Height=@Height) As Height
--  CROSS APPLY (Select ArcAngle=@ArcAngle) as ArcAngle
--  CROSS APPLY (Select Diameter=radius*2) as diameter
    CROSS APPLY (Select SqrRadius=Radius * Radius) as SqrRadius
--  CROSS APPLY (Select CubicRadius=Radius * Radius * Radius) as CubicRadius
--  CROSS APPLY (Select Circumference=diameter * Pi) as Circumference
    CROSS APPLY (Select circleSurface=SqrRadius * Pi) as circleSurface  
--  CROSS APPLY (Select angleRatio = ArcAngle/360.0) as angleRatio 
--  CROSS APPLY (Select ConeVolume=1/3.0 * circleSurface * Height) as ConeVolume 
    CROSS APPLY (Select CylinderVolume=circleSurface * Height) as CylinderVolume 
--  CROSS APPLY (Select SphereVolume=4/3.0 * Pi * CubicRadius) as SphereVolume 
--  CROSS APPLY (Select SphereVolumeTheOtherWay=4/3.0 * circleSurface * radius) as SphereVolumeTheOtherWay 
--  CROSS APPLY (Select ArcLength=angleRatio * Circumference) as ArcLength
--  CROSS APPLY (Select SectorSurface=angleRatio * circleSurface) as SectorSurface
GO
-- --------------------------------------------------------------------------------------------------
-- DEMO OF CONDITIONAL EXPRESSION LOGIC IN QUERIES
-- USE OF IIF OR OUTER APPLY WITH WHERE
-- LETS ASSUME THAT WE NEED TO EXTRACT ALL PARTS OF A FULL OR NOT SO FULL QUALIFIED FILE NAME
-- DRIVE, PATH ALONE, FILENAME ALONE, EXTENSION IF ANY, FILENAME.EXTENSION
-- ANY OF THESE MAY BE MISSING
-- --------------------------------------------------------------------------------------------------
SELECT *
FROM 
  (
  Values -- test data
    ('C:\Windows\System32\Drivers\Etc\Hosts.Sam')
  , ('C:\Etc\Hosts')
  , ('C:Hosts')
  , ('C:Hosts.Sam')
  , ('C:')
  , ('C:\')
  , ('Hosts')
  , ('\Windows\System32\Drivers\Etc\Hosts')
  ) as Test(FileExp)
  OUTER APPLY (Select Drive=LEFT(fileExp,2) Where FileExp LIKE '[a-z]:%') As Drive
  OUTER APPLY (Select StartPath=CHARINDEX('\', FileExp) Where FileExp LIKE '%\%') as StartPath
  CROSS APPLY (Select LgFileExp=LEN(FileExp)) as LgFileExp
  OUTER APPLY (Select EndPath=LEN(FileExp)+1-CHARINDEX('\', REVERSE(FileExp)) Where FileExp LIKE '%\%') as EndPath
  OUTER APPLY (Select PathWithNoDrive=SUBSTRING(fileExp, StartPath, EndPath-StartPath+1) Where StartPath is Not NULL) as PathWithNoDrive
  OUTER APPLY (Select LastDot=LEN(FileExp)+1-CHARINDEX('.', Reverse(FileExp))  Where FileExp LIKE '%.%') as LastDot
  OUTER APPLY (Select Ext=SUBSTRING(FileExp, LastDot+1, LgFileExp)) as Ext
  CROSS APPLY (Select [-Drive]=IIF(Drive IS NULL, FileExp, STUFF(FileExp,1,2,''))) as [-Drive]
  CROSS APPLY (Select [-DrivePath]=IIF(PathWithNoDrive IS NULL, [-Drive], STUFF([-Drive],1,Len(PathWithNoDrive),''))) as [-DrivePath]
  CROSS APPLY (Select FileName=IIF([-DrivePath]='', NULL, [-DrivePath])) as FileName
  OUTER APPLY (Select nameNoExt=IIF(Ext IS NULL, FileName, LEFT(FileName, Len(FileName)-Len(Ext)-1 ))) as NameNoExt
  OUTER APPLY (Select FileExpWithNoFileName=ISNULL(Drive,'')+ISNULL(PathWithNoDrive,'') Where Drive IS NOT NULL OR PathWithNoDrive IS NOT NULL) as FileExpWithNoFileName
GO
-- ----------------------------------------------------------------------------------------------
-- TRANSFORM EASILY THIS QUERY IN A GREAT FUNCTION ABOUT FILE PARTS
-- ----------------------------------------------------------------------------------------------
If OBJECT_ID('Dbo.GetFileParts') IS NOT NULL Drop Function Dbo.GetFileParts
GO
CREATE Function Dbo.GetFileParts (@FileExp as NVARCHAR(512))
RETURNS TABLE AS RETURN
SELECT Drive, PathWithNoDrive, FileName, nameNoExt, Ext, FileExpWithNoFileName
FROM 
  (Select FileExp = @FileExp) as FileExp
  OUTER APPLY (Select Drive=LEFT(fileExp,2) Where FileExp LIKE '[a-z]:%') As Drive
  OUTER APPLY (Select StartPath=CHARINDEX('\', FileExp) Where FileExp LIKE '%\%') as StartPath
  CROSS APPLY (Select LgFileExp=LEN(FileExp)) as LgFileExp
  OUTER APPLY (Select EndPath=LEN(FileExp)+1-CHARINDEX('\', REVERSE(FileExp)) Where FileExp LIKE '%\%') as EndPath
  OUTER APPLY (Select PathWithNoDrive=SUBSTRING(fileExp, StartPath, EndPath-StartPath+1) Where StartPath is Not NULL) as PathWithNoDrive
  OUTER APPLY (Select LastDot=LEN(FileExp)+1-CHARINDEX('.', Reverse(FileExp))  Where FileExp LIKE '%.%') as LastDot
  OUTER APPLY (Select Ext=SUBSTRING(FileExp, LastDot+1, LgFileExp)) as Ext
  CROSS APPLY (Select [-Drive]=IIF(Drive IS NULL, FileExp, STUFF(FileExp,1,2,''))) as [-Drive]
  CROSS APPLY (Select [-DrivePath]=IIF(PathWithNoDrive IS NULL, [-Drive], STUFF([-Drive],1,Len(PathWithNoDrive),''))) as [-DrivePath]
  CROSS APPLY (Select FileName=IIF([-DrivePath]='', NULL, [-DrivePath])) as FileName
  OUTER APPLY (Select nameNoExt=IIF(Ext IS NULL, FileName, LEFT(FileName, Len(FileName)-Len(Ext)-1 ))) as NameNoExt
  OUTER APPLY (Select FileExpWithNoFileName=ISNULL(Drive,'')+ISNULL(PathWithNoDrive,'') Where Drive IS NOT NULL OR PathWithNoDrive IS NOT NULL) as FileExpWithNoFileName
GO
-- USE IT
SELECT *
FROM 
  (
  Values -- test data
    ('C:\Windows\System32\Drivers\Etc\Hosts.Sam')
  , ('C:\Etc\Hosts')
  , ('C:Hosts')
  , ('C:Hosts.Sam')
  , ('C:')
  , ('C:\')
  , ('Hosts')
  , ('\Windows\System32\Drivers\Etc\Hosts')
  ) as Test(FileExp)
  OUTER APPLY Dbo.GetFileParts (FileExp) as R
-- USE IT WITH DIFFERENT COLUMNS AND COMPARE ACCESS PLAN
SELECT Drive, FileExpWithNoFileName
FROM 
  (
  Values -- test data
    ('C:\Windows\System32\Drivers\Etc\Hosts.Sam')
  , ('C:\Etc\Hosts')
  , ('C:Hosts')
  , ('C:Hosts.Sam')
  , ('C:')
  , ('C:\')
  , ('Hosts')
  , ('\Windows\System32\Drivers\Etc\Hosts')
  ) as Test(FileExp)
  OUTER APPLY Dbo.GetFileParts (FileExp) as R
-- -------------------------------------------------------------------------------------------
-- WORKING WITH DATA COMING FROM OTHER ROWS
-- SOLUTION : MAKE IT COMES INTO THE CURRENT ROW WITH THE OVER CLAUSE AND CTE
-- TYPICAL TRIGGER PROBLEM, COMPARING DATA BEFORE AND AFTER
-- -------------------------------------------------------------------------------------------
;WITH 
-- EMULATING TRIGGER CODE BY PROVIDING FAKE Deleted And Inserted trigger Pseudo tables
-- HELP TO DEVELOP TRIGGER CODE
  Deleted as 
  (
  Select 
    SchoolBoard=852000, StudentId=1000007, NOM='NomEle1', PNOM='PnomEle1'
  , AltFirstNameMissingCause=NULL, AltFirstNameExceptionFlag='1'
  , LegacyBirthLocaltion='010', BirthLocaltion='004'
  , DeceasedFlag='0', DeceasedStatus='A'
  )
, Inserted as 
  (
  Select 
    SchoolBoard=852000, StudentId=1000007, NOM='NomEle1', PNOM='PnomEle1'
  , AltFirstNameMissingCause='A', AltFirstNameExceptionFlag='0'
  , LegacyBirthLocaltion='007', BirthLocaltion='010'
  , DeceasedFlag='2', DeceasedStatus=NULL
  )
, StudentDataBeforeAndAfter as
  (
  Select 
    C.*
  , CnstOper.*
  , Oper
  , TriggerRowToKeep
  , AltFirstNameMissingCauseBefore  = FIRST_VALUE (ISNULL(AltFirstNameMissingCause,'')) OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , AltFirstNameExceptionFlagBefore = FIRST_VALUE (AltFirstNameExceptionFlag)           OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , BirthLocaltionBefore            = FIRST_VALUE (ISNULL(BirthLocaltion,''))           OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , LegacyBirthLocaltionBefore      = FIRST_VALUE (ISNULL(LegacyBirthLocaltion,''))     OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , DeceasedStatusBefore            = FIRST_VALUE (ISNULL(DeceasedStatus,''))           OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , DeceasedFlagBefore              = FIRST_VALUE (DeceasedFlag)                        OVER (Partition BY StudentId, SchoolBoard Order by Src)
  From 
    (VALUES (1,2,3) ) as CnstOper (Del, Ins, Upd) -- constants to add  to figure out if it is an delete only, an insert only or an update
    CROSS APPLY (Select SomethingInInsert=IIF(Exists(Select * from Inserted),Ins,0)) as SomethingInInserted
    CROSS APPLY (Select SomethingInDeleted=IIF(Exists(Select * from Deleted),Del,0)) as SomethingInDeleted
    CROSS APPLY (Select Oper= SomethingInInsert + SomethingInDeleted) as Oper
    -- CROSS APPLY MERGE BOTH INSERTED AND DELETED WITH UNION AND ADD A FLAG TO DISTINGUIST THEIR SOURCE FOR FIRST_VALUE OVER ORDER BY SRC
    CROSS APPLY (Select Src=Ins, * From Inserted UNION ALL Select Src=Del, * From Deleted) as C
    CROSS APPLY (Select TriggerRowToKeep=IIF((Oper IN (Ins,Upd) And Src=Ins) Or (Oper=Del And Src=Del), 1, 0)) as TriggerRowToKeep
  )
Select * From StudentDataBeforeAndAfter
GO
-- -----------------------------------------------------------------------------------
-- GENENERALIZE THE WAY TO IDENTIFY REAL OPERATION ON A INSERT, UPDATE, DELETE TRIGGER
-- AND FIGURE OUT WHERE FROM BOTH TO GET LAST VALUES
-- MAKES THE CODE THINNER
-- -----------------------------------------------------------------------------------
IF OBJECT_ID('dbo.TriggerInfoSource') IS NOT NULL Drop function dbo.TriggerInfoSource
GO
Create Function dbo.TriggerInfoSource (@ins as Int, @del Int)
Returns Table as Return
Select *
From 
  (VALUES (1,2,3) ) as CnstOper (Del, Ins, Upd) -- CONSTANTS TO ADD  TO FIGURE OUT IF IT IS AN DELETE ONLY, AN INSERT ONLY OR AN UPDATE
  CROSS APPLY -- THRUTH TABLE WITH MULTIPLE ANSWERS
  (
  Select RealOper = Upd, TriggerRowsToKeep= Ins Where @ins IS NOT NULL And @del IS NOT NULL UNION ALL
  Select RealOper = Ins, TriggerRowsToKeep= Ins Where @ins IS NOT NULL And @del IS NULL     UNION ALL
  Select RealOper = Del, TriggerRowsToKeep= Del Where @ins IS NULL     And @del IS NOT NULL 
  ) as T(realOper, triggerRowsToKeep)
GO
;WITH 
-- EMULATING TRIGGER CODE BY PROVIDING FAKE Deleted And Inserted trigger Pseudo tables
-- HELP TO DEVELOP TRIGGER CODE
  Deleted as 
  (
  Select 
    SchoolBoard=852000, StudentId=1000007, NOM='NomEle1', PNOM='PnomEle1'
  , AltFirstNameMissingCause=NULL, AltFirstNameExceptionFlag='1'
  , LegacyBirthLocaltion='010', BirthLocaltion='004'
  , DeceasedFlag='0', DeceasedStatus='A'
  )
, Inserted as 
  (
  Select 
    SchoolBoard=852000, StudentId=1000007, NOM='NomEle1', PNOM='PnomEle1'
  , AltFirstNameMissingCause='A', AltFirstNameExceptionFlag='0'
  , LegacyBirthLocaltion='007', BirthLocaltion='010'
  , DeceasedFlag='2', DeceasedStatus=NULL
  )
, StudentDataBeforeAndAfter as
  (
  Select 
    C.*
  , TrigInfSrc.*
  -- PARTITION DATA BY PRIMARY KEY TO GET BEFORE VALUES (FIRST VALUE ORDER BY SRC FOR THE SAME SUBJECT) 
  , AltFirstNameMissingCauseBefore  = FIRST_VALUE (ISNULL(AltFirstNameMissingCause,'')) OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , AltFirstNameExceptionFlagBefore = FIRST_VALUE (AltFirstNameExceptionFlag)           OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , BirthLocaltionBefore            = FIRST_VALUE (ISNULL(BirthLocaltion,''))           OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , LegacyBirthLocaltionBefore      = FIRST_VALUE (ISNULL(LegacyBirthLocaltion,''))     OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , DeceasedFlagBefore              = FIRST_VALUE (DeceasedFlag)                        OVER (Partition BY StudentId, SchoolBoard Order by Src)
  , DeceasedStatusBefore            = FIRST_VALUE (ISNULL(DeceasedStatus,''))           OVER (Partition BY StudentId, SchoolBoard Order by Src)
  From -- using triggerInfoSource reduce the code from 6 lines to 2, TriggerInfoSource returns constants Ins, Del, Upd And RealOper
    dbo.TriggerInfoSource((Select top (1) 1 From Inserted), (Select top (1) 1 From Deleted)) as TrigInfSrc
    CROSS APPLY (Select Src=Ins, * From Inserted UNION ALL Select Src=Del, * From Deleted) as C
  )
Select * -- get data with real change
From 
  StudentDataBeforeAndAfter
Where 
      Src=triggerRowsToKeep
  And (
         AltFirstNameMissingCauseBefore  <> ISNULL(AltFirstNameMissingCause,'')
      OR AltFirstNameExceptionFlagBefore <> AltFirstNameExceptionFlag
      OR BirthLocaltionBefore            <> ISNULL(BirthLocaltion,'')
      OR LegacyBirthLocaltionBefore      <> ISNULL(LegacyBirthLocaltion,'')
      OR DeceasedFlagBefore              <> DeceasedFlag
      OR DeceasedStatusBefore            <> ISNULL(DeceasedStatus,'')     
      )
GO
-- -------------------------------------------------------------------------------------------
-- WORKING CONDITIONALLY WITH DATA COMING FROM DIFFERENT SOURCES
-- SOLUTION : USE UNION ALL IN CROSS APPLY AND USE WHERE IN EACH QUERY TO SWITCH
-- KIND OF POLYMORPHISM IN QUERY
-- -------------------------------------------------------------------------------------------
IF OBJECT_ID('dbo.YearStartAndEndKinds') IS NOT NULL Drop View dbo.YearStartAndEndKinds
GO
CREATE VIEW dbo.YearStartAndEndKinds As 
Select *
From 
  (Values (1, 2, 3, 4)) As T (Ministere, ScolaireReg, ScolaireCrsEte, Finance)
GO
IF OBJECT_ID('dbo.YearStartAndEnd') IS NOT NULL Drop function dbo.YearStartAndEnd
GO
Create Function dbo.YearStartAndEnd (@Kind as Int, @Day as Date)
Returns Table as Return
Select Kind, YearOfKind, YearStartEnd, YearStartDate, NextYearStartDate, YearEndDate
From 
  dbo.YearStartAndEndKinds
  CROSS APPLY 
  (
  Values 
    (Ministere,      '0801')
  , (ScolaireReg,    '0731')
  , (ScolaireCrsEte, '0824')
  , (Finance,        '0301')
  ) as T(Kind, MMddStartDayOfYear)
  CROSS APPLY (Select DateStr=CONVERT(nvarchar, @Day, 112)) as DateStr
  CROSS APPLY (Select YearOfDay=LEFT(DateStr,4)) as YearOfDay
  CROSS APPLY (Select YearOfDayNum=Year(@Day)) as YearOfDayNum
  CROSS APPLY (Select MMddOfDay=RIGHT(DateStr,4)) as MMddOfDay
  CROSS APPLY (Select YearOfKind=IIF(MMddOfDay >= '0101' And MMddOfDay < MMddStartDayOfYear, YearOfDayNum-1, YearOfDayNum)) as YearOfType
  CROSS APPLY (Select YearStartEnd=STR(YearOfKind,4)+'-'+STR(YearOfKind+1,4)) As YearStartEnd
  CROSS APPLY (Select YearStartDate=Convert(datetime, STR(YearOfKind,4)+MMddStartDayOfYear)) As YearStartDate
  CROSS APPLY (Select NextYearStartDate=Convert(datetime, STR(YearOfKind+1,4)+MMddStartDayOfYear)) as NextYearStartDate
  CROSS APPLY (Select YearEndDate=NextYearStartDate-1) As YearEndDate
Where T.Kind = @Kind
GO
-- TESTING
Select t.*, ReturnedYearOfType=YearOfKind, YearStartEnd, YearStartDate, YearEndDate
From 
  (
  select Ministere, Day='20170101', Expected=2016 From YearStartAndEndKinds UNION ALL
  select Ministere, Day='20170731', Expected=2016 From YearStartAndEndKinds UNION ALL
  select Ministere, Day='20170801', Expected=2017 From YearStartAndEndKinds UNION ALL
  select Finance, Day='20170301', Expected=2017 From YearStartAndEndKinds
  ) as t (Kind, testDate, expected)
  CROSS APPLY dbo.YearStartAndEnd(Kind, testDate) as YSE
-- USING
Select *
From 
  SomeTableThatHasForWhichIWantYearByType as ST
  CROSS JOIN dbo.YearStartAndEndKinds 
  CROSS APPLY dbo.YearStartAndEnd(ScolaireReg, ST.ADateFromThisTable) as YSE
-- -------------------------------------------------------------------------------------
-- VERY IMPORTANT FUNCTION CAN BE INCLUDED IN UPDATE/DELETE/INSERT
-- THIS SAVE READ Network WRITE roundtrips
-- AND EVERYTHING IS DONE AT ONCE NOT EVEN 
-- -------------------------------------------------------------------------------------

-- SAMPLE WHERE WE UPDATE SCHOOLYEAR, BECAUSE THIS COLUMN IS ONLY OF SCOOLYEAR TYPE
Update AliasTable
Set SchoolYear = YSE.YearOfType
From 
  SomeTable as AliasTable
  CROSS JOIN dbo.YearStartAndEndKinds 
  CROSS APPLY dbo.YearStartAndEnd(ScolaireReg, AliasTable.SomeDate) as YSE

-- OR If YearType is Data in SomeTable, and in separate column we have year start and year end
Update AliasTable
Set 
  StartOfLegalYear = YSE.YearStartDate
, EndOfLegalYear   = YSE.YearEndDate
From 
  SomeTable as AliasTable
  CROSS JOIN dbo.YearStartAndEndKinds 
  CROSS APPLY dbo.YearStartAndEnd(AliasTable.YearKind, AliasTable.SomeDate) as YSE


