#!/bin/bash

echo "+++ Backing up vmail database"
mysqldump vmail -r /var/vmail/backup/mysql/vmail-0.9.7.sql

echo "+++ Ensuring /var/vmail has right permissions"
chmod 0755 /var/vmail -R

echo +++ Update SQL vmail structure
tmpf=$(tempfile)
echo "USE vmail;

-- DROP column
ALTER TABLE mailbox DROP COLUMN local_part;

-- Rename table
RENAME TABLE alias_moderators TO moderators;

-- Column used to limit number of mailing lists a domain admin can create
ALTER TABLE domain ADD COLUMN maillists INT(10) NOT NULL DEFAULT 0;

-- Column used to mark sql record is a mailing list
ALTER TABLE forwardings ADD COLUMN is_maillist TINYINT(1) NOT NULL DEFAULT 0;
ALTER TABLE forwardings ADD INDEX (\`is_maillist\`);

-- Table used to store mailing list accounts
CREATE TABLE IF NOT EXISTS maillists (
    id BIGINT(20) UNSIGNED AUTO_INCREMENT,
    address VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    -- Per mailing list transport. for example: 'mlmmj:example.com/listname'.
    transport VARCHAR(255) NOT NULL DEFAULT '',
    accesspolicy VARCHAR(30) NOT NULL DEFAULT '',
    maxmsgsize BIGINT(20) NOT NULL DEFAULT 0,
    -- name of the mailing list
    name VARCHAR(255) NOT NULL DEFAULT '',
    -- short introduction of the mailing list on subscription page
    description TEXT,
    -- a server-wide unique id (a 36-characters string) for each mailing list
    mlid VARCHAR(36) NOT NULL DEFAULT '',
    -- control whether newsletter-style subscription from website is enabled
    -- 1 -> enabled, 0 -> disabled
    is_newsletter TINYINT(1) NOT NULL DEFAULT 0,
    settings TEXT,
    created DATETIME NOT NULL DEFAULT '1970-01-01 01:01:01',
    modified DATETIME NOT NULL DEFAULT '1970-01-01 01:01:01',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE INDEX (address),
    UNIQUE INDEX (mlid),
    INDEX (is_newsletter),
    INDEX (domain),
    INDEX (active)
) ENGINE=InnoDB;" > $tmpf
mysql -u root vmail < $tmpf
rm $tmpf

echo +++ Amavisd: Add new SQL column maddr.email_raw to store mail address without address extension
tmpf=$(tempfile)
echo "
-- If subject contains emoji, varchar doesn't work well.
ALTER TABLE msgs MODIFY COLUMN subject VARBINARY(255) DEFAULT '';
ALTER TABLE msgs MODIFY COLUMN from_addr VARBINARY(255) DEFAULT '';

-- mail address without address extension: user+abc@domain.com -> user@domain.com
ALTER TABLE maddr ADD COLUMN email_raw varbinary(255) NOT NULL DEFAULT '';

-- index
CREATE INDEX maddr_idx_email_raw ON maddr (email_raw);

-- Create trigger to save email address withou address extension
-- user+abc@domain.com -> user@domain.com
DELIMITER //
CREATE TRIGGER \`maddr_email_raw\`
    BEFORE INSERT
    ON \`maddr\`
    FOR EACH ROW
    BEGIN
        IF (NEW.email LIKE '%+%') THEN
            SET NEW.email_raw = CONCAT(SUBSTRING_INDEX(NEW.email, '+', 1), '@', SUBSTRING_INDEX(new.email, '@', -1));
        ELSE
            SET NEW.email_raw = NEW.email;
        END IF;
    END;
//
DELIMITER ;" > $tmpf
mysql -u root amavisd < $tmpf
rm $tmpf

echo +++ Update iRedAPD
cd /opt/iRedAPD-2.2/tools
bash upgrade_iredapd.sh
