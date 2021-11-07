/*
 * Variables for LoyaltyPrograms pCode generation
 */
CREATE SEQUENCE RLPCount 
	START WITH 1 
	INCREMENT BY 1 
	NOMAXVALUE;

CREATE SEQUENCE TLPCount 
	START WITH 1 
	INCREMENT BY 1 
	NOMAXVALUE;

/*
 * Brands
 */
CREATE TABLE Brands (
    bname varchar(255),
    baddress varchar(255),
    username varchar(255),
    pass varchar(255),
    joinDate date,
    id integer GENERATED ALWAYS AS IDENTITY,
    constraint pk_brands_bId primary key (id)
);

/*
 * Loyalty Programs and Tiers
 */
CREATE TABLE LoyaltyPrograms (
    pName varchar(255),
    pCode varchar(255),
    isTiered varchar(1),
    bId integer,
    id integer GENERATED ALWAYS AS IDENTITY,
    constraint pk_loyaltyprograms_id primary key (id),
    constraint fk_bId foreign key (bId) references Brands (id)
);

CREATE TABLE Wallets (
	id integer GENERATED BY DEFAULT ON NULL AS IDENTITY,
    constraint pk_wallets_id primary key (id)
);

-- CREATE TABLE RegularPrograms (
--     id int,
--     constraint pk_id primary key (id)  
-- );

-- CREATE TABLE TieredPrograms (
--     id int,
--     constraint pk_id primary key (id)
-- );


CREATE TABLE Tiers (
    pId integer,
    tnum integer,
    tname varchar(255),
    multiplier float(3),
    threshold integer,
    constraint fk_tiers_pId foreign key (pId) references LoyaltyPrograms (id),
    constraint pk_tiers_tier primary key (pId, tnum),
    constraint valid_tier check(tnum >= 0 and tnum <= 2),
    constraint valid_multiplier check(multiplier > 0),
    constraint valid_threshold check(threshold >= 0)
);

/*
 * Customers and their Wallets
 */
CREATE TABLE Customers (
    cname varchar(255),
    phoneNumber varchar(15),
    caddress varchar(255),
    username varchar(255),
    pass varchar(255),
    id integer GENERATED ALWAYS AS IDENTITY,
    constraint pk_customers_cId primary key (id) 
);

/*
 * Admins
 */
CREATE TABLE Admins (
	username varchar(255),
	pass varchar(255),
	id integer GENERATED ALWAYS AS IDENTITY
);

CREATE TABLE CustomerWallets (
    cId integer UNIQUE,
    wId integer UNIQUE,
    constraint fk_customerwallets_cId foreign key (cId) references Customers (id),
    constraint fk_customerwallets_wId foreign key (wId) references Wallets (id),
    constraint pk_customerwallets_wallet primary key (cId, wId)
);

CREATE TABLE WalletParticipation (
    wId integer,
    pId integer,
    points integer,
    alltimepoints integer,
    tierNumber integer, -- A participation in a regular program will have a null tierNumber
    constraint pk_walletparticipation_participation primary key (wId, pId),
    constraint fk_walletparticipation_wId foreign key (wId) references Wallets (id),
    constraint fk_walletparticipation_pId foreign key (pId) references LoyaltyPrograms (id)
);

/*
 * Reward Earning
 */
CREATE TABLE ActivityCategories (
    acId varchar(255),
    acName varchar(255),
    constraint pk_activitycategories_acId primary key (acId)
);

CREATE TABLE ProgramActivities (
	pId integer,
    acId varchar(255),
    constraint pk_id primary key (pId, acId),
    constraint fk_programactivities_pId foreign key (pId) references LoyaltyPrograms (id),
    constraint fk_programactivities_acId foreign key (acId) references ActivityCategories (acId)
);

CREATE TABLE RewardEarningRules (
    pId integer,
    ruleVersion integer,
    ruleCode varchar(6),
    points integer,
    acId varchar(255),
    constraint pk_rewardearningrules_re primary key (pId, ruleVersion, ruleCode),
    constraint fk_rewardearningrules_pId foreign key (pId) references LoyaltyPrograms (id),
    constraint fk_rewardearningrules_ac foreign key (acId) references ActivityCategories (acId)
);

CREATE TABLE ActivityInstances (
    id integer GENERATED ALWAYS AS IDENTITY,
    instanceDate date,
    relevantInfo varchar(1000),
    pId integer,
    ruleVersion integer,
    ruleCode varchar(6),
    wId integer NOT NULL,
    constraint pk_activityInstances_aiId primary key (id),
    constraint fk_activityInstances_re foreign key (pId, ruleVersion, ruleCode) references RewardEarningRules (pId, ruleVersion, ruleCode),
    constraint fk_activityInstances_wId foreign key (wId) references Wallets (id)
);

/*
 * Reward Redeeming
 */
CREATE TABLE Rewards (
    rId varchar(255),
    rName varchar(255),
    constraint pk_rewards_rId primary key (rId)
);

CREATE TABLE ProgramRewards (
	pId integer,
    rId varchar(255),
    rewardQuantity integer,
    constraint pk_programrewards_id primary key (pId, rId),
    constraint fk_programrewards_pId foreign key (pId) references LoyaltyPrograms (id),
    constraint fk_programrewards_rId foreign key (rId) references Rewards (rId)
);

CREATE TABLE GiftCards (
    id integer GENERATED ALWAYS AS IDENTITY,
    pId integer,
    wId integer,
    cardValue float,
    expiryDate date,
    constraint pk_giftcards_gcId primary key (id),
    constraint fk_giftcards_pId foreign key (pId) references LoyaltyPrograms (id),
    constraint fk_giftcards_wId foreign key (wId) references Wallets (id)
);

CREATE TABLE RewardRedeemingRules (
    pId integer,
    ruleVersion integer,
    ruleCode varchar(6),
    points integer,
    rId varchar(255),
    quantity integer,
    gcVal integer,
    gcExp date,
    constraint pk_rewardredeemingrules_rr primary key (pId, ruleVersion, ruleCode),
    constraint fk_rewardredeemingrules_pId foreign key (pId) references LoyaltyPrograms (id),
    constraint fk_rewardredeemingrules_reward foreign key (rId) references Rewards (rId)
);

CREATE TABLE RewardInstances (
    id integer GENERATED ALWAYS AS IDENTITY,
    instanceDate date,
    pId integer,
    ruleVersion integer,
    ruleCode varchar(6),
    wId integer NOT NULL,
    constraint pk_rewardinstances_riId primary key (id),
    constraint fk_rewardinstances_re foreign key (pId, ruleVersion, ruleCode) references RewardRedeemingRules (pId, ruleVersion, ruleCode),
    constraint fk_rewardinstances_wId foreign key (wId) references Wallets (id)
);

/*
 * Trigger for dynamically generating pCode in LoyaltyPrograms
 */
CREATE OR REPLACE TRIGGER generateLPCode 
    BEFORE INSERT ON LoyaltyPrograms 
    FOR EACH ROW 
BEGIN
    IF :NEW.isTiered = 'Y' THEN 
	    :NEW.pCode := CONCAT('TLP', LPAD(TLPCount.NEXTVAL, 2, '0'));
	ELSE
        :NEW.pCode := CONCAT('RLP', LPAD(RLPCount.NEXTVAL, 2, '0'));
	END IF;
END;
/

/*
 * Trigger for adding wallet and customer-wallet binding for ever new customer
 */
CREATE OR REPLACE TRIGGER addWallets
	AFTER INSERT ON Customers
	FOR EACH
BEGIN
	INSERT INTO Wallets VALUES(NULL);
	INSERT INTO CustomerWallets(cId, wId) VALUES(:NEW.id, :New.id);
END 
/

/*
 * Assertion to ensure not username same between customers and brands
 */
CREATE ASSERTION noOverlapCustomerBrand
CHECK ( NOT EXISTS(SELECT C.username FROM Customers C, Brands B WHERE C.username = B.username))

/*
 * Assertion to ensure not username same between customers and admins
 */
CREATE ASSERTION noOverlapCustomerAdmin
CHECK ( NOT EXISTS(SELECT C.username FROM Customers C, Admins A WHERE C.username = A.username))

/*
 * Assertion to ensure not username same between customers and brands
 */
CREATE ASSERTION noOverlapAdminBrand
CHECK ( NOT EXISTS(SELECT A.username FROM Admins A, Brands B WHERE A.username = B.username))


