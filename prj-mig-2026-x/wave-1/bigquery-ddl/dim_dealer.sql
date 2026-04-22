-- BigQuery DDL: DIM_DEALER + DEALER_ANCESTOR (hierarchy navigation)
-- Authorised service network; Oracle-warehouse lineage. Closure replaces CONNECT BY in BQ.
-- Wave 1 — Dealer Hierarchy Network

CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.DIM_DEALER`
(
  DEALER_KEY        INT64      NOT NULL
    OPTIONS (description = 'Surrogate for this SCD2 dealer row; join to facts and capacity'),
  DEALER_ID         STRING(50) NOT NULL
    OPTIONS (description = 'Dealer business code, stable across systems; hierarchy natural key face'),
  DEALER_NAME       STRING(200)
    OPTIONS (description = 'Legal or trading name of the service outlet'),
  DEALER_TYPE       STRING(50)
    OPTIONS (description = 'Authorised service, main dealer, satellite—recall work eligibility may vary'),
  REGION_CODE       STRING(20)
    OPTIONS (description = 'Geographic or commercial region for routing and reporting'),
  COUNTRY_CODE      STRING(5)
    OPTIONS (description = 'ISO-style country; market and regulatory slice'),
  PARENT_DEALER_ID  STRING(50)
    OPTIONS (description = 'Immediate parent in dealer tree; NULL for root; materialised in DEALER_ANCESTOR for navigation'),
  IS_ROOT           BOOL       DEFAULT FALSE
    OPTIONS (description = 'True if this node has no parent in the org tree for this design'),
  EFFECTIVE_FROM    DATE       NOT NULL
    OPTIONS (description = 'SCD2 start of validity for this version of the dealer record'),
  EFFECTIVE_TO      DATE
    OPTIONS (description = 'SCD2 end of validity; NULL = current open row'),
  IS_CURRENT        BOOL       DEFAULT TRUE
    OPTIONS (description = 'True for the current row for this dealer business key'),
  _SOURCE_SYSTEM    STRING(50) DEFAULT 'ORACLE_DW'
    OPTIONS (description = 'Provenance, e.g. ORACLE_DW / dealer master from warehouse stream'),
  _LOADED_AT        TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'Technical load time; audit, not org change event time')
)
CLUSTER BY DEALER_ID, REGION_CODE
OPTIONS (
  description = 'Dealer SCD2 dimension: authorised service network, regions, and recall-service context. Ancestor path pre-computed in DEALER_ANCESTOR. Source: Stream B / Oracle-warehouse style. Cluster: DEALER_ID, REGION_CODE.'
);

-- Pre-computed ancestor table (replaces recursive CONNECT BY in Oracle)
CREATE OR REPLACE TABLE `my-gcp-project.recall_dw.DEALER_ANCESTOR`
(
  DEALER_ID   STRING(50) NOT NULL
    OPTIONS (description = 'Descendant dealer id in the hierarchy; join key to DIM_DEALER.DEALER_ID'),
  ANCESTOR_ID STRING(50) NOT NULL
    OPTIONS (description = 'An ancestor in the org tree, including the root; used for root lookup when DEPTH=1'),
  DEPTH       INT64      NOT NULL
    OPTIONS (description = 'Hops to ancestor; 1 = immediate parent, greater = higher ancestors per closure rules'),
  _LOADED_AT  TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
    OPTIONS (description = 'Time this row was last written in a rebuild of the closure')
)
CLUSTER BY DEALER_ID
OPTIONS (
  description = 'Transitive closure for dealer org chart: O(1) path queries vs recursive tree walks. Root DEPTH=1 used by lineage views. Replaces Oracle CONNECT BY for BQ. Cluster: DEALER_ID.'
);
