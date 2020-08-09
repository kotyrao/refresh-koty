select distinct
		CULPRINT_TRAN.tx_user_name AS culprit, 
		CULPRINT_TRAN.tx_transaction_id AS culpritId,
		VICTIM_TRAN.tx_user_name AS victim,
		VICTIM_TRAN.tx_transaction_id AS victimId,
		VICTIM_TRAN.resource_id,
		RESOURCES.resource_table_id AS tableId,
		RESOURCES.resource_index_id AS IndexId,
		RESOURCES.resource_page_number AS pageId,
		RESOURCES.resource_row_id AS rowId,
		RESOURCES.resource_key
from ima_locks VICTIM
left outer join ima_locks CULPRINT
	on CULPRINT.vnode=VICTIM.vnode
	and CULPRINT.resource_id=VICTIM.resource_id
	and uppercase(CULPRINT.lock_state) = 'GR'
	and uppercase(VICTIM.lock_state) !='GR'
left outer join ima_locklist VICTIM_LOCKLIST
	on VICTIM_LOCKLIST.vnode = VICTIM.vnode
	and VICTIM_LOCKLIST.locklist_id = VICTIM.locklist_id
left outer join ima_locklist CULPRINT_LOCKLIST
	on CULPRINT_LOCKLIST.vnode = VICTIM.vnode
	and CULPRINT_LOCKLIST.locklist_id = VICTIM.locklist_id
left outer join ima_log_transactions VICTIM_TRAN
	on VICTIM_TRAN.vnode = VICTIM_LOCKLIST.vnode 
	and VICTIM_TRAN.tx_transaction_id = VICTIM_LOCKLIST.locklist_session_id
left outer join ima_log_transactions CULPRIT_TRAN
	on CULPRIT_TRAN.vnode = CULPRIT_TRAN.vnode 
	and CULPRIT_TRAN.tx_transaction_id = CULPRIT_TRAN.locklist_session_id
left outer join ima_resources RESOURCES
	on VICTIM.resource_id = RESOURCES.resource_id
where CULPRIT_TRAN.tx_transaction_id is not null;
