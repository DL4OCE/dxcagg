-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema dxc_agg
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema dxc_agg
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `dxc_agg` DEFAULT CHARACTER SET latin1 COLLATE latin1_german1_ci ;
USE `dxc_agg` ;

-- -----------------------------------------------------
-- Table `dxc_agg`.`sota`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dxc_agg`.`sota` ;

CREATE TABLE IF NOT EXISTS `dxc_agg`.`sota` (
  `association` VARCHAR(2) NOT NULL,
  `region` VARCHAR(2) NOT NULL,
  `number` VARCHAR(3) NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`association`, `region`, `number`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `dxc_agg`.`dok`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dxc_agg`.`dok` ;

CREATE TABLE IF NOT EXISTS `dxc_agg`.`dok` (
  `district` VARCHAR(1) NOT NULL,
  `number` VARCHAR(2) NOT NULL,
  `name` VARCHAR(36) NOT NULL,
  PRIMARY KEY (`district`, `number`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `dxc_agg`.`iota`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dxc_agg`.`iota` ;

CREATE TABLE IF NOT EXISTS `dxc_agg`.`iota` (
  `continent` VARCHAR(2) NOT NULL,
  `number` VARCHAR(3) NOT NULL,
  `name` VARCHAR(60) NOT NULL,
  PRIMARY KEY (`continent`, `number`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `dxc_agg`.`spot`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dxc_agg`.`spot`;

CREATE TABLE IF NOT EXISTS `dxc_agg`.`spot` (
--   `idspot` INT(11) NOT NULL,
  `dx_call` VARCHAR(20) NOT NULL,
--   `timestamp` INT NOT NULL,
  `utc` VARCHAR(4) NOT NULL,
  `qrg_khz` DOUBLE NOT NULL,
  `spotter_call` VARCHAR(20) NULL,
  `suffix_p` INT NULL,
  `suffix_m` INT NULL,
  `suffix_mm` INT NULL,
  `suffix_am` INT NULL,
  `suffix_qrp` INT NULL,
  `suffix_a` INT NULL,
  `suffix_lh` INT NULL,
  `band` VARCHAR(8) NULL,
  `sota_association` VARCHAR(2) NOT NULL,
  `sota_region` VARCHAR(2) NOT NULL,
  `sota_number` VARCHAR(3) NOT NULL,
  `dok_district` VARCHAR(1) NOT NULL,
  `dok_number` VARCHAR(2) NOT NULL,
  `iota_continent` VARCHAR(2) NOT NULL,
  `iota_number` VARCHAR(3) NOT NULL,
  `qsl_manager` VARCHAR(20) NULL,
  `rda` VARCHAR(6) NULL,
  `comment` VARCHAR(255) NULL,
  `mode` VARCHAR(20) NULL,
  `ms` INT NULL,
  `tropo` INT NULL,
  `special_event` INT NULL,
  `split` INT NULL,
  `beacon` INT NULL,
  `source` VARCHAR(30) NULL,
  `timestamp_created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
-- INT NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   PRIMARY KEY (`idspot`),
  INDEX `fk_spot_sota_assoc_idx` (`sota_association` ASC, `sota_region` ASC, `sota_number` ASC),
  INDEX `fk_spot_dok1_idx` (`dok_district` ASC, `dok_number` ASC),
  INDEX `fk_spot_iota1_idx` (`iota_continent` ASC, `iota_number` ASC)
  -- ,
  -- CONSTRAINT `fk_spot_sota_assoc`
  --   FOREIGN KEY (`sota_association` , `sota_region` , `sota_number`)
  --   REFERENCES `dxc_agg`.`sota` (`association` , `region` , `number`)
  --   ON DELETE NO ACTION
  --   ON UPDATE NO ACTION,
  -- CONSTRAINT `fk_spot_dok1`
  --   FOREIGN KEY (`dok_district` , `dok_number`)
  --   REFERENCES `dxc_agg`.`dok` (`district` , `number`)
  --   ON DELETE NO ACTION
  --   ON UPDATE NO ACTION,
  -- CONSTRAINT `fk_spot_iota1`
  --   FOREIGN KEY (`iota_continent` , `iota_number`)
  --   REFERENCES `dxc_agg`.`iota` (`continent` , `number`)
  --   ON DELETE NO ACTION
    -- ON UPDATE NO ACTION
    )
ENGINE = InnoDB;


CREATE USER 'dxc_agg'@'%' IDENTIFIED BY 'baier123';
GRANT ALL PRIVILEGES ON dxc_agg.* TO 'dxc_agg'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

