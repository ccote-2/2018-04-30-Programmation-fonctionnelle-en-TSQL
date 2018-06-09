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
-- HAVING LEARNED SOME TRICKS ABOUT DOING FUNCTIONAL PROGRAMMING IS SQL AND REUSE OF IT
-- FROM FUNCTION, LET'S START LEARNING ABOUT OF TO MAKE THE DATABASE VIRTUAL TO APPS
------------------------------------------------------------------------------------------------------
--
-- INDEPENDANCE BETWEEN DATABASES AND APPLICATION DEPENDS MAY BE ATTAINED BY 
-- TABLE CONTRACTS, AND FUNCTION TO FILL THEM IN AND VALIDATE THEM BEFORE COMMITTING THEM TO 
-- THE DATABASE
-- THIS HIDES DATABASE UNDERLYING STRUCTURE FOREVER
-- THIS PROVIDES TO THE OOP PROGRAMMING MODEL REDUCE SETS TO WORK ON, LEAVING BUSINESS RULES RESOLUTION
-- WHERE IS PERFORM BEST, AT DATABASE LEVEL OR THE OOP SIDE
-- THIS IS FUNDAMENTAL, BECAUSE HUMANS AND INTERFACES AND PROGRAM OFTEN NEED A DENORMALIZED VIEW OF THE DATA
-- DATABASE TABLE CONTRACT ARE THE BRIDGE TO NORMALIZE AND DENORMALIZE DATA 
--
--IF OBJECT_ID('') IS NOT NULL DROP   
if object_id('dbo.ForeignKeyInfoByTbId') IS NOT NULL Drop Function dbo.ForeignKeyInfoByTbId
GO
create function dbo.ForeignKeyInfoByTbId (@TbId Int)
returns table 
AS
RETURN
(
With 
  ForeignKeySelector as
  (
  Select * 
  From 
    Sys.foreign_keys FK
  Where @TbId IS NULL
  UNION ALL
  Select FK.* 
  From 
    Sys.foreign_keys FK
  Where @TbId IS NOT NULL
    And FK.parent_object_id = @TbId
  )
, ForeignKeyData as
  (
  select 
    Names.Scn
  , Names.Tab
  , Names.FullTbName
  , f.parent_object_id
  , f.object_id
  , FkName=F.name
  , f.Is_system_named
  , Names.RefTbName
  , FkCols
  , RefKeyCols
  , delete_referential_action_desc=Replace (F.delete_referential_action_desc, '_', ' ') 
  , update_referential_action_desc=Replace (F.update_referential_action_desc, '_', ' ') 
  from 
    ForeignKeySelector f
    CROSS APPLY
    (
    Select 
      Scn=object_schema_name(f.parent_object_id) 
    , Tab=object_name(f.parent_object_id) 
    , FullTbName='['+object_schema_name(f.parent_object_id)+'].[' +object_name(f.parent_object_id)+']'
    , RefTbName='['+object_schema_name(f.referenced_object_id)+'].[' +object_name(f.referenced_object_id)+']'
    ) As Names
    CROSS APPLY
    (
    Select 
      FkCols = 
      Stuff
      (
        (
        Select convert(nvarchar(max), ', '+Quotename(COL_NAME (Fkc.parent_object_id, Fkc.parent_column_id ))) as [text()]
        From sys.foreign_key_columns Fkc
        Where constraint_object_id = F.object_id
        Order BY FKc.constraint_column_id 
        FOR XML PATH('') 
        ) 
      , 1
      , 2
      , ''
      ) 
    ) as FkCols
    cross apply
    (
    Select 
      RefKeyCols =
      Stuff
      (
        (
        Select convert(nvarchar(max), ', '+Quotename(COL_NAME (Idxc.object_id, Idxc.Index_Column_Id))) as [text()]
        From sys.index_columns Idxc
        Where 
            Idxc.object_id = F.referenced_object_id
        And Idxc.Index_id = f.key_index_id
        Order BY Idxc.Key_Ordinal
        FOR XML PATH('') 
        ) 
      , 1
      , 2
      , ''
      ) 
    ) as RefKeyCols
  )
select AddForeignKey, DropForeignKey, Fkd.*
from 
  ForeignKeyData Fkd
  Cross Apply
  (
  Select 
    AddForeignKekTmp =
    '
     Alter Table #tab# Add Constraint [#FKName#] FOREIGN KEY (#FkCols#) 
     References #RefTbName# (#RefkeyCols#)
     ON DELETE #delete_referential_action_desc# ON UPDATE #update_referential_action_desc#; ' collate Database_Default 
  , DropForeignKeyTmp =
    'If Exists(Select * From sys.foreign_keys where name = ''#FKName#'') alter table #tab# drop constraint [#FKName#]; ' collate database_default 
  ) as Fkt
  cross apply (Select SqlDrop0=Replace(DropForeignKeyTmp, '#Tab#', Fkd.FullTbName))  as SqlDrop0
  cross apply (Select SqlDrop1=Replace(SqlDrop0, '#FkName#', Fkd.FkName))  as SqlDrop1
  Cross Apply (Select DropForeignKey=SqlDrop1) as DropForeignKey
  cross apply (Select SqlAdd0=Replace(AddForeignKekTmp, '#Tab#', Fkd.FullTbName))  as SqlAdd0
  cross apply (Select SqlAdd1=Replace(SqlAdd0, '#FkName#', Fkd.FkName))  as SqlAdd1
  cross apply (Select SqlAdd2=Replace(SqlAdd1, '#FkCols#', Fkd.FkCols))  as SqlAdd2
  cross apply (Select SqlAdd3=Replace(SqlAdd2, '#RefTbName#', Fkd.RefTbName))  as SqlAdd3
  cross apply (Select SqlAdd4=Replace(SqlAdd3, '#RefkeyCols#', Fkd.RefkeyCols))  as SqlAdd4
  cross apply (Select SqlAdd5=Replace(SqlAdd4, '#delete_referential_action_desc#', Fkd.delete_referential_action_desc))  as SqlAdd5
  cross apply (Select SqlAdd6=Replace(SqlAdd5, '#update_referential_action_desc#', Fkd.update_referential_action_desc))  as SqlAdd6
  Cross Apply (Select AddForeignKey=SqlAdd6) as AddForeignKey
)
-- 
GO
if object_id('dbo.ForeignKeyInfoReferrinngTo') IS NOT NULL Drop Function dbo.ForeignKeyInfoReferrinngTo
GO
create function dbo.ForeignKeyInfoReferrinngTo (@TbId Int)
Returns table AS RETURN
Select F.*
From 
  sys.foreign_keys
  CROSS APPLY Dbo.ForeignKeyInfoByTbId (parent_object_id) as F
Where referenced_object_id = @TbId
GO

IF SCHEMA_ID('DbContract') IS NULL Exec ('Create Schema DbContract Authorization Dbo')
IF SCHEMA_ID('Student') IS NULL Exec ('Create Schema Student Authorization Dbo')

-- needs this to make a function able to get newid
IF OBJECT_ID('DbContract.NewIdFromView') IS NOT NULL DROP View DbContract.NewIdFromView
GO
CREATE VIEW DbContract.NewIdFromView AS SELECT NEWID() as vnewId
go

-- drop referring fk in case
Declare @Sql Nvarchar(max) = ''
Select @sql = @sql + F.DropForeignKey
From Dbo.ForeignKeyInfoReferrinngTo (object_id('Student.Identification')) as F
Print @Sql
Exec (@sql)

-- OUR REAL DATA
IF OBJECT_ID('Student.Identification') IS NOT NULL DROP Table Student.Identification  
create table Student.Identification 
(
  Id Int Constraint [PKStudent.Identification] Primary Key CLustered
, lastname nvarchar(50)
, firstname nvarchar(50)
, dadFirstname nvarchar(50)
, dadLastname nvarchar(50)
, momFirstname nvarchar(50)
, momLastName nvarchar(50)
, CGFirstName nvarchar(50)
, CGLastName nvarchar(50)
, PhoneOwner nvarchar(1)
, PhoneToCall nvarchar(10)
)
go 
-- FUNCTION TO FEED THE CONTRACT
IF OBJECT_ID('DbContract.ManageCareGiversGet') IS NOT NULL DROP Function DbContract.ManageCareGiversGet
go
CREATE FUNCTION DbContract.ManageCareGiversGet (@id Int)
RETURNS TABLE As RETURN
SELECT 
    Spid=@@SPID, txId=vNewid
  , ID, lastname, firstname
  , dadfirstname, dadlastname
  , momfirstname, momlastname
  , CGFirstName, CGLastName
  , PhoneOwner, PhoneToCall
  , ValidationMsgs=CONVERT(nvarchar(max), NULL)
From 
  Student.Identification 
  CROSS JOIN DbContract.NewIdFromView 
Where ID=@id
GO
-- CREATE THE CONTRACT FROM CONTRACT FEEDER FUNCTION
IF OBJECT_ID('DbContract.ManageCareGivers') IS NOT NULL DROP Table DbContract.ManageCareGivers
Select Top 0 * INTO DbContract.ManageCareGivers
From DbContract.ManageCareGiversGet(1) 
go
-- FACULTATIVE 
-- CREATE THE CONTRACT FROM CONTRACT FEEDER FUNCTION
IF OBJECT_ID('DbContract.ManageCareGiversLog') IS NOT NULL DROP Table DbContract.ManageCareGiversLog
Select Top 0 *, LogDate=GETDATE() 
INTO DbContract.ManageCareGiversLog
From DbContract.ManageCareGivers
go
-- MAIN EXERCICE OF THE WHOLE THING
-- HOW-TO ABOUT CONTRACT VALIDATTION
IF OBJECT_ID('DbContract.ManageCareGiversValidate') IS NOT NULL DROP Function DbContract.ManageCareGiversValidate
go
CREATE FUNCTION DbContract.ManageCareGiversValidate (@txid UniqueIdentifier NULL)
RETURNS TABLE As RETURN
SELECT 
  Spid, txId 
, ID, lastname, firstname
, dadfirstname, dadLastname
, momfirstname, momlastname
, CGFirstName, CGLastName
, PhoneOwner, PhoneToCall
, NewValidationMsgs
From 
  (Select TxIdToSearch=@txid) as Search
  CROSS APPLY (Select * From DbContract.ManageCareGivers Where Spid=@@Spid And (TxIdToSearch IS NULL Or txId=TxIdToSearch)) as M
  OUTER APPLY
  (
  Select MsgsNames=
    (
    Select MsgsAboutName as [text()]
    From 
      (Select 1 dummy) as Dual -- dummy but requested if I want a cross apply
      CROSS APPLY 
      (
      Select 'dad', dadFirstname, DadLastname Union All 
      Select 'mom', MomFirstname, MomLastname Union All 
      Select 'res', CGFirstName, CGLastName 
      ) as CareGivers (carGiver, CGFirstName, CGLastName)
      OUTER APPLY
      (
      Select MsgsAboutName=FORMATMESSAGE('Partial name are forbidden for cargiver %s'+NCHAR(13), CarGiver) 
      Where
         CGLastName IS NULL     and CGFirstName IS NOT NULL 
      OR CGLastName IS NOT NULL and CGFirstName IS NULL 
      ) MsgsAboutName
    ORDER BY carGiver -- when concatenating, order by type and then caregiver
    FOR XML PATH('')
    ) 
  ) as MsgsNames
  OUTER APPLY
  (
  Select MsgsAboutPhone=FORMATMESSAGE('Phone''s %s number is not set while phone to cargiver is set'+NCHAR(13)) 
  Where PhoneOwner IN ('D', 'M', 'C') And PhoneToCall IS NOT NULL
  ) MsgsAboutPhone
  OUTER APPLY
  (
  Select MsgsAboutPhoneOwnerNotSet=FORMATMESSAGE('Phone''s %s number is set while its onwer ins''t'+NCHAR(13), PhoneToCall) 
  Where PhoneOwner IS NULL And PhoneToCall IS NOT NULL
  ) MsgsAboutPhoneOwnerNotSet
  OUTER APPLY
  (
  Select MsgsAboutPhoneOwner=FORMATMESSAGE('Phone owner must be ''D'', ''M'', ''R''\n')+'' 
  Where PhoneOwner IS NOT NULL And PhoneOwner NOT IN ('D', 'M', 'C')
  ) MsgsAboutPhoneOwner
  CROSS APPLY (Select NewValidationMsgs=REPLACE(ISNULL(MsgsNames,'')+ISNULL(MsgsAboutPhoneOwnerNotSet,'') + ISNULL(MsgsAboutPhoneOwner,''),'&#x0D;', nchar(13))) as NewValidationMsgs
GO
--delete From DbContract.ManageCareGivers where spid=@@spid
--select * from DbContract.ManageCareGivers

-- CLEANUP TRIGGER FOR A GIVEN CONTRACT EXERCICE
IF OBJECT_ID('DbContract.ManageCareGivers_TrigInsteadofI') IS NOT NULL DROP Trigger DbContract.ManageCareGivers_TrigInsteadofI
go
CREATE Trigger DbContract.ManageCareGivers_TrigInsteadofI
ON DbContract.ManageCareGivers
Instead Of Insert
AS
Begin -- cleanup leftover
  Delete From DbContract.ManageCareGivers Where spid = @@spid
  Insert into DbContract.ManageCareGivers Select * from Inserted
End
go
-- GENERIC LOG FUNCTION FOR ANY CONTRACT TYPE TO BUILD SQL
IF OBJECT_ID('DbContract.SqlLog') IS NOT NULL DROP Function DbContract.SqlLog
go
CREATE FUNCTION DbContract.SqlLog (@procid Int)
RETURNS TABLE As RETURN
SELECT Sql
From 
  (select Template='Insert into [#ContractSchName#].[#ContractName#log] Select *, Getdate() From [#ContractSchName#].[#ContractName#]') as Template
  CROSS APPLY (Select ParentObjId=Parent_object_id From sys.objects Where object_id=@procid) as ParentObjId
  Cross Apply (Select ContractSchName=Object_schema_name(ParentObjId)) As ContractSchName
  CROSS APPLY (Select ContractName=OBJECT_NAME(ParentObjId) ) as ContractName
  CROSS Apply (Select Sql0=REPLACE(Template, '#ContractName#', ContractName)) as Sql0
  CROSS Apply (Select Sql=REPLACE(Sql0, '#ContractSchName#', ContractSchName)) as Sql
GO
-- Select * From DbContract.SqlLog (Object_id('DbContract.ManageCareGivers_TrigIUD'))

-- TRIGGER THAT APPLY CONTRACT RULES FROM CONTRACTVALIDE, AND UPDATE THE REAL STUFF
IF OBJECT_ID('DbContract.ManageCareGivers_TrigIUD') IS NOT NULL DROP Trigger DbContract.ManageCareGivers_TrigIUD
go
CREATE Trigger DbContract.ManageCareGivers_TrigIUD
ON DbContract.ManageCareGivers
FOR Insert,Update
AS
Begin
  -- DEPENDING ON DESIGN CHOICE, ONE MAY PERFORM OPERATIONS ONLY IF THERE IS NO MESSAGE FOR THE TRANSACION
  -- OR PERFORM OPERATIONS THAT HAVE NO MESSAGES AND LEAVE THE OTHER ALONE
  ;With TxState As
  (
  Select 
    C.*, TrigInfSrc.*
  From -- using triggerInfoSource reduce the code from 6 lines to 2, TriggerInfoSource returns constants Ins, Del, Upd And RealOper
    dbo.TriggerInfoSource((Select top (1) 1 From Inserted), (Select top (1) 1 From Deleted)) as TrigInfSrc
    CROSS APPLY (Select Src=Ins, * From Inserted UNION ALL Select Src=Del, * From Deleted) as C
  )
  Update Ctr -- validation of contract row is performed on insert (when insert from the get fonction is performed) and on update
  Set ValidationMsgs=Coalesce(ValidationMsgDel, ValidationMsgUpd)
  From 
    (Select * From TxState Where Src=triggerRowsToKeep) as TxFinalState
    JOIN DbContract.ManageCareGivers as Ctr ON Ctr.txid = TxFinalState.txid 
    CROSS APPLY (select CleanUpMode=trigger_nestlevel( Object_id('DbContract.ManageCareGivers_TrigInsteadofI'))) as CleanUpMode
    OUTER APPLY (Select ValidationMsgDel='No delete operation is allowed on this contract' Where realOper=Del And CleanUpMode = 0)  ValidationMsgDel
    OUTER APPLY (Select ValidationMsgUpd=NewValidationMsgs From DbContract.ManageCareGiversValidate(TxFinalState.txid) Where realOper IN (Upd, Ins)) as ValidationMsgUpd

  ;With TxState As
  (
  Select 
    C.*, TrigInfSrc.*
  From -- using triggerInfoSource reduce the code from 6 lines to 2, TriggerInfoSource returns constants Ins, Del, Upd And RealOper
    dbo.TriggerInfoSource((Select top (1) 1 From Inserted), (Select top (1) 1 From Deleted)) as TrigInfSrc
    CROSS APPLY (Select Src=Ins, * From Inserted UNION ALL Select Src=Del, * From Deleted) as C
  )
  Update RealStuff
  Set 
    dadFirstname=Ctr.dadFirstname, dadLastname=Ctr.dadLastname
  , momFirstname=Ctr.momFirstname, momLastname=Ctr.momLastname
  , CGFirstName=Ctr.CGFirstName, CGLastName=Ctr.CGLastName
  , PhoneOwner=Ctr.PhoneOwner, PhoneToCall=Ctr.PhoneToCall
  From 
    (Select * From TxState Where Src=triggerRowsToKeep And RealOper=Upd) as TxFinalState
    JOIN DbContract.ManageCareGivers as Ctr ON Ctr.txid = TxFinalState.txid 
    JOIN Student.Identification as RealStuff On RealStuff.Id = Ctr.id
  Where Ctr.ValidationMsgs = ''
  If @@ROWCOUNT>0
  Begin
    Declare @Sql Nvarchar(max)
    Select @Sql = Sql From DbContract.SqlLog(@@procid) 
    Exec (@Sql)
  End
End
GO
-- ----------- HOW TO USE IT --------------------------------------
-- USE THIS WAY IF YOU DIRECTLY KNOW STUDENT ID
-- SET & SHOW TEST DATA
-- ----------- HOW TO USE IT --------------------------------------
Truncate table Student.Identification 
Insert into Student.Identification 
([Id], [lastname], [firstname], [dadFirstname], [dadLastname], [momFirstname], [momLastName], [CGFirstName], [CGLastName], [PhoneOwner], [PhoneToCall])
Values 
  (1234, 'Me', 'him','Papa', 'Him', 'Mama', 'Her', null, null, 'D', '5145551122')
, (2345, 'Me2', 'him2','Papa2', 'Him2', 'Mama2', 'Her2', null, null, 'M', '5145551122')
Select * From Student.Identification

------------------------------ UNNORMALIZED CONTRACT UNNORMALIZED TABLES ------------------------------------------
------------------------------ UNNORMALIZED CONTRACT UNNORMALIZED TABLES ------------------------------------------

------------ STARTS HERE -------------------------------------
Insert Into DbContract.ManageCareGivers
Select * From DbContract.ManageCareGiversGet(1234)
--Select * From DbContract.ManageCareGivers Where spid=@@spid
------------ MODIFY THE COLUMNS, THE TRIGGER PUTS VALIDATION MESSAGES AND UPDATES WHAT DOESN'T HAVE MESSAGES -------------
------------ THIS IS AN EXAMPLE, THE TRIGGER COULD BE MADE TO DO NOTHING IF A SINGLE VALIDATION MESSAGE IS ISSUED -------
------------ THIS FIRST ATTEMPT DOES NO UPDATE, SINGLE ROW WITH MESSAGE
Update DbContract.ManageCareGivers 
Set DadlastName = null, momFirstname = NULL, PhoneOwner= NULL 
Where spid=@@spid
------------ SHOW RESULTS ------------------------
Select * From DbContract.ManageCareGiversValidate(null)

------------ CORRECT VALUES, WHICH IS CORRECT IS SAVED -----------------------
Update DbContract.ManageCareGivers 
Set DadlastName = 'DadLN', momFirstname = 'MOMfm', PhoneOwner= 'M'
Where spid=@@spid
------------ VERIFY EVERY PART -----------------------------------------------
Select * From DbContract.ManageCareGivers
Select * From DbContract.ManageCareGiversValidate(null)
Select * From Student.Identification
Select * From DbContract.ManageCareGiversLog

-- ----------- ANOTHER WAY TO FEED THE CONTRACT IT IF YOU DON'T KNOW STUDENT ID AND GET IT FROM ANOTHER VIEW / TABLE -----------------
-- ----------- A VIEW WHICH WOULD BE A BETTER FIT WITH WHOLE PHILOSPHY OF ABSTRACTING THE DATABASE TO APP ------
-- ----------- This is a different way to do the get part ------------------------------------------------------
Insert Into DbContract.ManageCareGivers
Select Ctr.* 
From 
  Student.Identification as SI
  CROSS APPLY DbContract.ManageCareGiversGet(SI.ID) as Ctr
Where 
  SI.momFirstname = 'Tremblay' And SI.momLastName Like 'AR%ISE'
-- THE REST WORKS THE SAME ONCE CONTRACT IS FEEDED ...
GO

------------------------------ UNNORMALIZED CONTRACT - NORMALIZED TABLES ------------------------------------------
------------------------------ UNNORMALIZED CONTRACT - NORMALIZED TABLES ------------------------------------------
-----------------------------------------------------------------------------------
-- MODIFY THE DATABASE
-- STUDENT.IDENTIFICATION DOESN'T HOLD CAREGIVER DATA ANYMORE
-- NEW NORMALIZED STUDENT.CARGIVER TABLE
-- MAKE A NEW CONTRACT TYPE
-- DRIVE OLD CONTRACT TO NEW CONTRACT
-----------------------------------------------------------------------------------
IF OBJECT_ID('Student.CaregiverLegalRelationTypes') IS NOT NULL DROP View Student.CaregiverLegalRelationTypes
go
create view Student.CaregiverLegalRelationTypes as 
Select * From (Values (1,2,3)) as CT (Parent, CGFromFamily, CGNotFromFamily)
go
Declare @Sql Nvarchar(max) = ''
Select @sql = @sql + F.DropForeignKey
From Dbo.ForeignKeyInfoReferrinngTo (object_id('Student.Identification')) as F
Print @Sql
Exec (@sql)
go
IF OBJECT_ID('Student.Identification') IS NOT NULL DROP Table Student.Identification
create table Student.Identification
(
  Id Int Constraint [PKStudent.Identification] Primary Key CLustered
, FirstName nvarchar(50)
, LastName nvarchar(50)
)
GO
IF OBJECT_ID('Student.Caregiver') IS NOT NULL DROP Table Student.Caregiver
create table Student.Caregiver 
(
  StudentId Int  
  Constraint [FK_Student.Caregiver_To_Student.Identification] FOREIGN KEY REFERENCES Student.Identification (id) 
  ON DELETE CASCADE
, legalRelation Int
, gender Char(1)
, email nvarchar(128)      NULL
, firstName nvarchar(50)
, LastName nvarchar(50)
, PhoneNumber Nvarchar(10) NULL
)
GO
-- PRESERVE OLD CONTRACT INTERFACE
IF OBJECT_ID('DbContract.ManageCareGiversGet') IS NOT NULL DROP Function DbContract.ManageCareGiversGet
GO
CREATE FUNCTION DbContract.ManageCareGiversGet (@id Int)
RETURNS TABLE As RETURN
SELECT 
  spid=@@SPID, txid=NewIdFromView.vnewId
, Si.ID, Si.Firstname, Si.LastName
, dadfirstname, dadLastname
, momfirstname, momlastname
, CGFirstName, CGLastName
, PhoneOwner=COALESCE(DadPhoneOwner, MomPhoneOwner, CGPhoneOwner)
, PhoneToCall=COALESCE(DadPhone, MomPhone, CGPhone)
, ValidationMsgs=CONVERT(nvarchar(max),NULL)
From 
  (Select * from student.Identification Where Id=@id) As Si
  CROSS JOIN DbContract.NewIdFromView 
  CROSS APPLY Student.CaregiverLegalRelationTypes
  OUTER APPLY 
  (
  Select dadfirstname=Firstname, dadlastname=LastName, dadPhone=PhoneNumber, DadPhoneOwner='D' 
  From 
    Student.Caregiver as SCG 
  Where SCG.StudentId = Si.Id And legalRelation=Parent And gender='M'
  ) as DadInfo
  OUTER APPLY 
  (
  Select momfirstname=Firstname, momlastname=LastName,  momPhone=PhoneNumber, MomPhoneOwner='M'
  From Student.Caregiver as SCG 
  Where SCG.StudentId = Si.Id And legalRelation=Parent And gender='F'
  ) as MomInfo
  OUTER APPLY 
  (
  Select CGFirstName=Firstname, CGLastName=LastName,  CGPhone=PhoneNumber, CGPhoneOwner='C' 
  From Student.Caregiver as SCG 
  Where SCG.StudentId = Si.Id And legalRelation IN (CGFromFamily, CGNotFromFamily) 
  ) as TutInfo
-- CREATE THE CONTRACT FROM CONTRACT FEEDER FUNCTION
GO
IF OBJECT_ID('DbContract.ManageCareGivers') IS NOT NULL DROP Table DbContract.ManageCareGivers
Select Top 0 * INTO DbContract.ManageCareGivers
From DbContract.ManageCareGiversGet(1) 
go
-- FACULTATIVE 
-- CREATE THE CONTRACT FROM CONTRACT FEEDER FUNCTION
IF OBJECT_ID('DbContract.ManageCareGiversLog') IS NOT NULL DROP Table DbContract.ManageCareGiversLog
Select Top 0 *, LogDate=GETDATE() 
INTO DbContract.ManageCareGiversLog
From DbContract.ManageCareGivers
go
-- MAIN EXERCICE OF THE WHOLE THING, ESSENTIALLY VALIDATION DO NOT CHANGE, ON THE SAME CONTRACT, BUT IT COULD FOR 
-- ANY NEW BUSINESS RULE THAT IMPLIES THE NEW NORMALIZED TABLE
IF OBJECT_ID('DbContract.ManageCareGiversValidate') IS NOT NULL DROP Function DbContract.ManageCareGiversValidate
go
CREATE FUNCTION DbContract.ManageCareGiversValidate (@txid UniqueIdentifier NULL)
RETURNS TABLE As RETURN
SELECT 
  Spid, txId 
, ID, lastname, firstname
, dadfirstname, dadLastname
, momfirstname, momlastname
, CGFirstName, CGLastName
, PhoneOwner, PhoneToCall
, NewValidationMsgs
From 
  (Select TxIdToSearch=@txid) as Search
  CROSS APPLY (Select * From DbContract.ManageCareGivers Where Spid=@@Spid And (TxIdToSearch IS NULL Or txId=TxIdToSearch)) as M
  OUTER APPLY
  (
  Select MsgsNames=
    (
    Select MsgsAboutName as [text()]
    From 
      (Select 1 dummy) as Dual -- dummy but requested if I want a cross apply
      CROSS APPLY 
      (
      Select 'dad', dadFirstname, DadLastname Union All 
      Select 'mom', MomFirstname, MomLastname Union All 
      Select 'res', CGFirstName, CGLastName 
      ) as CareGivers (carGiver, CGFirstName, CGLastName)
      OUTER APPLY
      (
      Select MsgsAboutName=FORMATMESSAGE('Partial name are forbidden for cargiver %s'+NCHAR(13), CarGiver) 
      Where
         CGLastName IS NULL     and CGFirstName IS NOT NULL 
      OR CGLastName IS NOT NULL and CGFirstName IS NULL 
      ) MsgsAboutName
    ORDER BY carGiver -- when concatenating, order by type and then caregiver
    FOR XML PATH('')
    ) 
  ) as MsgsNames
  OUTER APPLY
  (
  Select MsgsAboutPhone=FORMATMESSAGE('Phone''s %s number is not set while phone to cargiver is set'+NCHAR(13)) 
  Where PhoneOwner IN ('D', 'M', 'C') And PhoneToCall IS NOT NULL
  ) MsgsAboutPhone
  OUTER APPLY
  (
  Select MsgsAboutPhoneOwnerNotSet=FORMATMESSAGE('Phone''s %s number is set while its onwer ins''t'+NCHAR(13), PhoneToCall) 
  Where PhoneOwner IS NULL And PhoneToCall IS NOT NULL
  ) MsgsAboutPhoneOwnerNotSet
  OUTER APPLY
  (
  Select MsgsAboutPhoneOwner=FORMATMESSAGE('Phone owner must be ''D'', ''M'', ''R''\n')+'' 
  Where PhoneOwner IS NOT NULL And PhoneOwner NOT IN ('D', 'M', 'C')
  ) MsgsAboutPhoneOwner
  CROSS APPLY (Select NewValidationMsgs=REPLACE(ISNULL(MsgsNames,'')+ISNULL(MsgsAboutPhoneOwnerNotSet,'') + ISNULL(MsgsAboutPhoneOwner,''),'&#x0D;', nchar(13))) as NewValidationMsgs
GO
-- CLEANUP TRIGGER FOR A GIVEN CONTRACT EXERCICE
IF OBJECT_ID('DbContract.ManageCareGivers_TrigInsteadofI') IS NOT NULL DROP Trigger DbContract.ManageCareGivers_TrigInsteadofI
go
CREATE Trigger DbContract.ManageCareGivers_TrigInsteadofI
ON DbContract.ManageCareGivers
Instead Of Insert
AS
Begin -- cleanup leftover
  Delete From DbContract.ManageCareGivers Where spid = @@spid
  Insert into DbContract.ManageCareGivers Select * from Inserted
End
go

-- TRIGGER THAT APPLY CONTRACT RULES FROM CONTRACTVALIDATE, AND UPDATE THE NEW NORMALIZED CAREGIVER TABLE FROM UNNORMALIZED REPRESENTATION
IF OBJECT_ID('DbContract.ManageCareGivers_TrigIUD') IS NOT NULL DROP Trigger DbContract.ManageCareGivers_TrigIUD
go
CREATE Trigger DbContract.ManageCareGivers_TrigIUD
ON DbContract.ManageCareGivers
FOR Insert,Update
AS
Begin
  -- DEPENDING ON DESIGN CHOICE, ONE MAY PERFORM OPERATIONS ONLY IF THERE IS NO MESSAGE FOR THE TRANSACION
  -- OR PERFORM OPERATIONS THAT HAVE NO MESSAGES AND LEAVE THE OTHER ALONE
  ;With TxState As
  (
  Select 
    C.*, TrigInfSrc.*
  From -- using triggerInfoSource reduce the code from 6 lines to 2, TriggerInfoSource returns constants Ins, Del, Upd And RealOper
    dbo.TriggerInfoSource((Select top (1) 1 From Inserted), (Select top (1) 1 From Deleted)) as TrigInfSrc
    CROSS APPLY (Select Src=Ins, * From Inserted UNION ALL Select Src=Del, * From Deleted) as C
  )
  Update Ctr -- validation of contract row is performed on insert (when insert from the get fonction is performed) and on update
  Set ValidationMsgs=Coalesce(ValidationMsgDel, ValidationMsgUpd)
  From 
    (Select * From TxState Where Src=triggerRowsToKeep) as TxFinalState
    JOIN DbContract.ManageCareGivers as Ctr ON Ctr.txid = TxFinalState.txid 
    CROSS APPLY (select CleanUpMode=trigger_nestlevel( Object_id('DbContract.ManageCareGivers_TrigInsteadofI'))) as CleanUpMode
    OUTER APPLY (Select ValidationMsgDel='No delete operation is allowed on this contract' Where realOper=Del And CleanUpMode = 0)  ValidationMsgDel
    OUTER APPLY (Select ValidationMsgUpd=NewValidationMsgs From DbContract.ManageCareGiversValidate(TxFinalState.txid) Where realOper IN (Upd, Ins)) as ValidationMsgUpd

  -- the contract is all about managing unnormalized caregiver data contract and put it back it in normalized table
  ;With TxState As
  (
  Select 
    C.*, TrigInfSrc.*
  From -- using triggerInfoSource reduce the code from 6 lines to 2, TriggerInfoSource returns constants Ins, Del, Upd And RealOper
    dbo.TriggerInfoSource((Select top (1) 1 From Inserted), (Select top (1) 1 From Deleted)) as TrigInfSrc
    CROSS APPLY (Select Src=Ins, * From Inserted UNION ALL Select Src=Del, * From Deleted) as C
  )
  Update CG
  Set 
    Firstname=NewDataForCareGiver.FirstName
  , Lastname=NewDataForCareGiver.LastName
  , PhoneNumber=NewOrOldPhoneToCall
  From 
    (Select * From TxState Where Src=triggerRowsToKeep And RealOper=Upd) as TxFinalState
    JOIN DbContract.ManageCareGivers as Ctr ON Ctr.txid = TxFinalState.txid 
    JOIN Student.Identification as StudId On StudId.Id = Ctr.id
    CROSS APPLY Student.CaregiverLegalRelationTypes
    OUTER APPLY (Select GuessedCGType=CGFromFamily Where StudId.LastName=Ctr.momlastname Or StudId.lastname=Ctr.DadLastName) as GuessedCGType
    CROSS APPLY 
    (
    Select 
      Legal=Parent
    , Gender='M',  FirstName=Ctr.dadfirstname, LastName=Ctr.dadlastname, PhoneOwner='D', PhoneNumber=Ctr.PhoneToCall UNION ALL 
    Select 
      legal=Parent
    , Gender='F',  FirstName=Ctr.momfirstname, LastName=Ctr.momlastname, PhoneOwner='M', PhoneNumber=Ctr.PhoneToCall UNION ALL 
    Select 
      legal=ISNULL(GuessedCGType, CGNotFromFamily) 
    , Gender=NULL, FirstName=Ctr.CGfirstname,  LastName=Ctr.CGlastname,  PhoneOwner='C', PhoneNumber=Ctr.PhoneToCall 
    ) as NewDataForCareGiver

    -- figure out the real row that match the caregivers, through the legal relation and typical gender, if not found, no update
    -- for non-parent caregiver the original table neither the contract didn't had any gender, so we match without gender
    JOIN Student.Caregiver as CG 
    On  CG.StudentId = StudId.id 
    And CG.legalRelation = NewDataForCareGiver.Legal 
    And ISNULL(CG.gender,'') = ISNULL(NewDataForCareGiver.Gender, '')

    CROSS APPLY (Select NewOrOldPhoneToCall=IIF(Ctr.PhoneOwner=NewDataForCareGiver.PhoneOwner, NewDataForCareGiver.PhoneNumber, CG.PhoneNumber)) as NewOrOldPhoneToCall

  Where -- no error 
      Ctr.ValidationMsgs = ''
      -- real changes
  And (  -- if no difference no update
         ISNULL(CG.firstName,'')<>ISNULL(NewDataForCareGiver.FirstName, '') 
      Or ISNULL(CG.LastName,'')<>ISNULL(NewDataForCareGiver.LastName, '') 
      Or ISNULL(CG.PhoneNumber,'')<>ISNULL(NewOrOldPhoneToCall, '') 
      )
  If @@ROWCOUNT>0
  Begin
    Declare @Sql Nvarchar(max)
    Select @Sql = Sql From DbContract.SqlLog(@@procid) 
    Exec (@Sql)
  End
End
GO
-- ----------- HOW TO USE IT --------------------------------------
-- USE THIS WAY IF YOU DIRECTLY KNOW STUDENT ID
-- SET & SHOW TEST DATA
-- ----------- HOW TO USE IT --------------------------------------
-- ----------- SET SOME DATA FOR DEMO -----------------------------
Delete Student.Identification 
Insert into Student.Identification ([Id], [lastname], [firstname])
Values 
  (1234, 'Me', 'him')
, (2345, 'Me2', 'him2')
Select * From Student.Identification

Insert Into Student.Caregiver (StudentId, legalRelation, gender, firstName, lastname, email, phoneNumber)
Select R.*
From
  Student.CaregiverLegalRelationTypes
  CROSS APPLY 
  (
  Values  
    (1234, Parent, 'M', 'Papa',  'Him',  null, '5145551122')
  , (1234, Parent, 'F', 'Mama',  'Her',  null, '5145551122')
  , (2345, Parent, 'M', 'Papa2', 'Him2', null, '5145551122')
  , (2345, Parent, 'F', 'Mama2', 'Her2', null, '5145551122')
  ) as R (StudentId, legalRelation, gender, firstName, lastname, email, phoneNumber)

------------ STARTS HERE -------------------------------------
Insert Into DbContract.ManageCareGivers
Select * From DbContract.ManageCareGiversGet(1234)
--Select * From DbContract.ManageCareGivers Where spid=@@spid
------------ MODIFY THE COLUMNS, THE TRIGGER PUTS VALIDATION MESSAGES AND UPDATES WHAT DOESN'T HAVE MESSAGES -------------
------------ THIS IS AN EXAMPLE, THE TRIGGER COULD BE MADE TO DO NOTHING IF A SINGLE VALIDATION MESSAGE IS ISSUED -------
------------ THIS FIRST ATTEMPT DOES NO UPDATE, SINGLE ROW WITH MESSAGE
Update DbContract.ManageCareGivers 
Set DadlastName = null, momFirstname = NULL, PhoneOwner= NULL 
Where spid=@@spid
------------ SHOW RESULTS ------------------------
Select * From DbContract.ManageCareGiversValidate(null)

------------ CORRECT VALUES, WHICH IS CORRECT IS SAVED -----------------------
Update DbContract.ManageCareGivers 
Set DadlastName = 'DadLN', momFirstname = 'MOMfm', PhoneOwner= 'M'
Where spid=@@spid
------------ VERIFY EVERY PART -----------------------------------------------
Select * From DbContract.ManageCareGivers
Select * From DbContract.ManageCareGiversValidate(null)
Select * From Student.Identification
Select * From Student.Caregiver
Select * From DbContract.ManageCareGiversLog
