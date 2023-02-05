DELIMITER $$

DROP EVENT IF EXISTS yearly_delete_stale_audit_rows;

CREATE EVENT yearly_delete_stale_audit_rows
ON SCHEDULE
    -- AT '2019-05-01'
    EVERY 1 YEAR STARTS '2019-01-01' ENDS '2029-01-01'
DO BEGIN
    DELETE FROM payments_audit
    WHERE action_date < NOW() - INTERVAL 1 YEAR;
END $$

DELIMITER ;