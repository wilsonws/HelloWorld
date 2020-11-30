SELECT 
DATE_FORMAT(lo.create_time,'%Y%u')date
,count(1)dd_cnt
,sum(if(lo.status in (3,4,8,9,10,11,14,16),1,0))tg_dd_cnt
,sum(if(isnull(lo.maturity),0,1)) fk_dd_cnt
,sum(if(lo.status in (3,4,8,9,10,11,14,16),1,0))/count(1) tg_rate
,sum(if(isnull(lo.maturity),0,1))/count(1)fk_rate
,sum(if(lo.maturity<now(),1,0))dq_cnt
-- 没还过,宽松标准
,sum(if(lo.maturity<now() and isnull(rf.repaid_amt),1,0))dqyq_cnt
-- 没结清，严格标准
-- ,sum(if(lo.maturity<now() and (isnull(rf.repaid_amt) or rf.is_finish=0),1,0))dqyq_cnt
,sum(if(lo.maturity<now() and isnull(rf.repaid_amt),1,0))/sum(if(lo.maturity<now(),1,0)) dqyq_rate
-- ,sum(if(lo.maturity<now() and (isnull(rf.repaid_amt) or rf.is_finish=0),1,0))/sum(if(lo.maturity<now(),1,0)) dqyq_rate
,sum(if(lo.maturity<now() and (isnull(rf.repaid_amt) or DATEDIFF(rf.repay_time,lo.maturity)>0),1,0))/sum(if(lo.maturity<now(),1,0)) od1
,sum(if(DATEDIFF(now(),lo.maturity)>2 and (isnull(rf.repaid_amt) or DATEDIFF(rf.repay_time,lo.maturity)>2),1,0))/sum(if(DATEDIFF(now(),lo.maturity)>2,1,0)) od3
,sum(if(DATEDIFF(now(),lo.maturity)>6 and (isnull(rf.repaid_amt) or DATEDIFF(rf.repay_time,lo.maturity)>6),1,0))/sum(if(DATEDIFF(now(),lo.maturity)>6,1,0)) od7
from 
(
SELECT 
lo.create_time,
ISNULL(lo.seed_user_id) not_ddc,
isnull(lc.mask_id)not_sys2,
case when ISNULL(lo.seed_user_id)=0 then lo.seed_user_id else lo.user_id end as new_user_id,
lo.id,lo.seed_id,lo.seed_user_id,lo.company_id,lc.name company_name,
lo.amt,lo.amt-lo.apply_fee as actual_amt,
lo.period_days,lo.status,lo.first_audit_time,lo.last_audit_time,lo.maturity,lo.is_repeat,lo.is_platform_new,lo.installation_source,lo.extension_platform,lo.logic_score,
ui.mobile,ui.identity,ui.create_time as register_time,ui.real_name,ui.card_no
from loan.loan_order lo 
left join loan.company lc 
on lo.company_id=lc.id 
left join loan.user_info ui 
on lo.seed_user_id=ui.user_id
-- where lo.id='6891832049905793818'
where lo.create_time>'2020-10-01' 
and lo.is_repeat=1
)lo 
left join 
(SELECT rf.loan_id,max(rf.maturity)due_time,max(rf.repay_time)repay_time,max(rf.finish)is_finish,sum(case when rf.canceled=0 then rf.amt else null end) as repaid_amt
from 
loan.repay_flow rf 
GROUP BY 1)rf 
on lo.id=rf.loan_id
-- where lo.company_id='5f8e9be39799ea8faa38b4f1'
where lo.not_sys2=0
-- and lo.is_repeat=1
GROUP BY 1 
ORDER BY 1 desc
-- and lo.is_repeat=1
;


