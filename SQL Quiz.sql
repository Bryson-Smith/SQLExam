USE master
GO 
Create table Application_Fact
(
lob_desc		varchar(50)
,app_sbmtd_dt	date
,app_aprvd_dt	date
,app_rjctd_dt	date
,loan_amt		decimal
,dlr_id			int 
,veh_id			int
)

Insert into Application_Fact
(lob_desc		
 ,app_sbmtd_dt	
 ,app_aprvd_dt	
 ,app_rjctd_dt	
 ,loan_amt		
 ,dlr_id			
 ,veh_id
 ) values
 ('Lease'
,'5-1-2020'
,DATEADD(day, (ABS(CHECKSUM(NEWID())) % 44692), 0)
,Null 
,6888.00
,FLOOR(RAND()*(20-10+1))+10
,FLOOR(RAND()*(123143451-10+1))+10
)

Select *
from Application_Fact
where 1=1
and app_rjctd_dt is null 

--Drop table if exists Dealer_dim
Create table Dealer_dim
(
dlr_id				int
,dlr_nm				varchar(50)
,regn_id			int
,prefrd_dlr_ind		bit
,valid_from_dt		date
,valid_to_dt		date
)

Insert into Dealer_dim
(
dlr_id			
,dlr_nm			
,regn_id		
,prefrd_dlr_ind			
,valid_from_dt	
,valid_to_dt	
)
values
 (FLOOR(RAND()*(20-10+1))+10
, concat('Dealer',' ',FLOOR(RAND()*(20-10+1))+10)
,FLOOR(RAND()*(20-10+1))+10
,0
,DATEADD(day, (ABS(CHECKSUM(NEWID())) % 44692), 0)
,DATEADD(day, (ABS(CHECKSUM(NEWID())) % 44692), 0)
)

Select *
from Dealer_dim

--Drop table if exists Vehicle_dim
Create table Vehicle_dim
(
veh_id				int
,new_use_desc		varchar(50)
,make_desc			varchar(50)
,model_desc			varchar(50)
,year_num			int
)


Insert into Vehicle_dim
(
veh_id			
,new_use_desc			
,make_desc		
,model_desc		
,year_num	
)
values
 (106707225
,'Used'
,'Dodge'
,'Ram'
,2020
)

Select *
from Vehicle_dim


--Drop table if exists Region_dim
Create table Region_dim
(
regn_id					int
,regn_nm				varchar(50)
,regn_lead_nm			varchar(50)
,valid_from_qt			date
,valid_to_qt			date
)

Insert into Region_dim
(
regn_id				
,regn_nm			
,regn_lead_nm		
,valid_from_qt	
,valid_to_qt	
)
values
 (FLOOR(RAND()*(20-10+1))+10
,'South'
,'Bob'
,DATEADD(day, (ABS(CHECKSUM(NEWID())) % 44692), 0)
,DATEADD(day, (ABS(CHECKSUM(NEWID())) % 44692), 0)
)

Select *
from Region_dim


Select *
from Application_Fact

/*Question 1 */
Select Top 5 
	MONTH(app_sbmtd_dt)				as 'Month'
	,datename(MONTH,app_sbmtd_dt)	as 'MonthName'
	,COUNT(veh_id)			as 'ApplicationCount'
from Application_Fact(nolock) 
where 1=1 
and app_sbmtd_dt	between '1-1-2020' and '12-31-2020'
group by MONTH(app_sbmtd_dt)
		,datename(MONTH,app_sbmtd_dt)
order by COUNT(veh_id) desc


/*Question 2 */
Select Top 5 
	MONTH(AF.app_sbmtd_dt)				as 'Month'
	,datename(MONTH,AF.app_sbmtd_dt)	as 'MonthName'
	,COUNT(AF.veh_id)				as 'ApplicationCount'
from Application_Fact(nolock)  as AF
inner join Dealer_dim(nolock)  as DD on DD.dlr_id = AF.dlr_id and DD.prefrd_dlr_ind = 1 
where 1=1 
and app_sbmtd_dt between '1-1-2020' and '12-31-2020'
group by MONTH(app_sbmtd_dt),datename(MONTH,app_sbmtd_dt)
order by  COUNT(Af.veh_id) desc


/*Question 3 

3. What is the percentage of preferred dealer applications approved with respect to overall applications approved for year 2020?

*/
Select 
	(COUNT(Case  When app_aprvd_dt is not null then 1 else null end)*100	/(Select Count(app_aprvd_dt) from 	Application_Fact))
from Application_Fact(nolock)  as AF
inner join Dealer_dim(nolock)  as DD on DD.dlr_id = AF.dlr_id and DD.prefrd_dlr_ind = 1 --and GETDATE() between valid_from_dt and valid_to_dt
where 1=1 
and app_sbmtd_dt between '1-1-2020' and '12-31-2020'



/*Question 4 */

Select 
DD.dlr_nm,
	(COUNT(Case  When app_aprvd_dt is not null then 1 else null end)*100	/(Select Count(app_aprvd_dt) from 	Application_Fact))
from Application_Fact(nolock)  as AF
inner join Dealer_dim(nolock)  as DD on DD.dlr_id = AF.dlr_id 
where 1=1 
and app_sbmtd_dt between DATEADD(quarter,-1,'12-31-2020') and '12-31-2020'
group by DD.dlr_nm
having (COUNT(Case  When app_aprvd_dt is not null then 1 else null end)*100	/(Select Count(app_aprvd_dt) from 	Application_Fact))>50


/*Question 5 */
Select regn_nm
,COUNT(Case  When VD.new_use_desc = 'Used' then 1 else null end) as 'Used Count'
,COUNT(Case  When VD.new_use_desc = 'New' then 1 else null end) as 'New Count'
from Region_dim (nolock)  as R
left join Dealer_dim (nolock) as DD on DD.regn_id = R.regn_id
left join Application_Fact (nolock) as AF on DD.dlr_id = AF.dlr_id
left join Vehicle_dim(nolock) as VD on VD.veh_id=AF.veh_id
where 1=1 
and app_sbmtd_dt between DATEADD(quarter,-1,'12-31-2020') and '12-31-2020'
group by regn_nm
having Count(Case  When VD.new_use_desc = 'Used' then 1 else null end)>COUNT(Case  When VD.new_use_desc = 'New' then 1 else null end)

/*Question 6 */
Select regn_nm,count(Case  When app_sbmtd_dt is not null then 1 else null end) as 'Application Submitted'
,count(Case  When app_aprvd_dt is not null then 1 else null end) as 'Application Accepted'
from Region_dim(nolock) as R
left join Dealer_dim (nolock) as DD on DD.regn_id = R.regn_id
left join Application_Fact (nolock) as AF on DD.dlr_id = AF.dlr_id
group by regn_nm
order by count(Case  When app_sbmtd_dt is not null then 1 else null end) desc ,count(Case  When app_aprvd_dt is not null then 1 else null end) desc


/*Question 7 */

Select MONTH(af.app_sbmtd_dt) as 'Month 2020'
,Count(Case when EOMonth(af.app_sbmtd_dt) = EOMonth(af.app_sbmtd_dt) Then 1 Else Null end) as '2020'
,Count(Case when EOMonth(af.app_sbmtd_dt) = dateAdd(year,-1,EOMonth(af.app_sbmtd_dt)) Then 1 Else Null end) as '2019'
,ABS((Count(Case when EOMonth(af.app_sbmtd_dt) = EOMonth(af.app_sbmtd_dt) Then 1 Else Null end) - Count(Case when EOMonth(af.app_sbmtd_dt) = dateAdd(year,-1,EOMonth(af.app_sbmtd_dt)) Then 1 Else Null end))) as 'Difference'
from Application_Fact as af
group by  MONTH(af.app_sbmtd_dt)

/*Question 8 */
/*A*/
Select 
Rank() over(partition by R.regn_nm order by Count(AF.app_aprvd_dt) desc) as DealerRank,Dd.dlr_nm,R.regn_nm,Count(AF.app_aprvd_dt) as 'Approval Count'
into #RankA
from Dealer_dim as DD
left Join Region_dim as R on R.regn_id = DD.regn_id
Left Join Application_Fact as AF on AF.dlr_id = DD.dlr_id
where 1=1 
group By DD.dlr_nm, R.regn_nm
order by Count(AF.app_aprvd_dt) desc,regn_nm desc

Select *
from #RankA
where 1=1
and DealerRank = 1


/*B*/
Select Rank() over(partition by R.regn_nm order by Count(AF.app_rjctd_dt)asc) as DealerRank,Dd.dlr_nm,R.regn_nm, Count(AF.app_rjctd_dt) as 'Rejected Count'
from Dealer_dim as DD
left Join Region_dim as R on R.regn_id = DD.regn_id
Left Join Application_Fact as AF on AF.dlr_id = DD.dlr_id
group By DD.dlr_nm,R.regn_nm
order by Count(AF.app_rjctd_dt) asc


/*C*/
Select regn_nm, Sum(AF.loan_amt) as 'TotalLoanAmount'
from Dealer_dim as DD
left Join Region_dim as R on R.regn_id = DD.regn_id
Left Join Application_Fact as AF on AF.dlr_id = DD.dlr_id
where 1=1
and app_aprvd_dt is not null 
group By regn_nm
having Sum(AF.loan_amt)>= 2000000

/*D*/
Select DealerPercent,Regn_nm,dlr_nm,DealerRank
From (
		Select cume_dist() over(partition by R.regn_nm order by Count(AF.app_rjctd_dt)desc) as DealerPercent, R.regn_nm,DD.dlr_nm,Count(AF.app_rjctd_dt) as 'Count'
		,Rank() over(partition by R.regn_nm order by Count(AF.app_rjctd_dt)desc) as DealerRank
		from Dealer_dim as DD
		left Join Region_dim as R on R.regn_id = DD.regn_id
		Left Join Application_Fact as AF on AF.dlr_id = DD.dlr_id
		group By regn_nm, dlr_nm
		--order by cume_dist() over(partition by R.regn_nm order by Count(AF.app_rjctd_dt)desc)
		) as Sub
Where 1=1 
and DealerRank = 1

/*E*/

Select DealerPercent,Regn_nm,dlr_nm,DealerRank
From (
		Select cume_dist() over(partition by R.regn_nm order by Count(AF.app_rjctd_dt)asc) as DealerPercent, R.regn_nm,DD.dlr_nm,Count(AF.app_rjctd_dt) as 'Count'
		,Rank() over(partition by R.regn_nm order by Count(AF.app_rjctd_dt)asc) as DealerRank
		from Dealer_dim as DD
		left Join Region_dim as R on R.regn_id = DD.regn_id
		Left Join Application_Fact as AF on AF.dlr_id = DD.dlr_id
		group By regn_nm, dlr_nm
		--order by cume_dist() over(partition by R.regn_nm order by Count(AF.app_rjctd_dt)desc)
		) as Sub
Where 1=1 
and DealerRank = 1




/*
Select regn_nm, (COUNT(Case  When app_rjctd_dt is not null then 1 else null end)*100	/(Select Count(app_rjctd_dt) from 	Application_Fact))As 'Ratio'
from Dealer_dim as DD
left Join Region_dim as R on R.regn_id = DD.regn_id
Left Join Application_Fact as AF on AF.dlr_id = DD.dlr_id
group By regn_nm
order by (COUNT(Case  When app_rjctd_dt is not null then 1 else null end)*100	/(Select Count(app_rjctd_dt) from 	Application_Fact)) asc

*/