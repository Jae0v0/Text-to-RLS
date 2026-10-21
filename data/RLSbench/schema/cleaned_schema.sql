--
-- PostgreSQL database dump
--

\restrict zmy31IpEU25wUIuLqv8tcW0c4vxfKzYNSIKlfW67nptDtmSGL13AmjeaduVqdad

-- Dumped from database version 14.22 (Ubuntu 14.22-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.22 (Ubuntu 14.22-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: common; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA common;


--
-- Name: engineering; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA engineering;


--
-- Name: finance; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA finance;


--
-- Name: hr; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA hr;


--
-- Name: operations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA operations;


--
-- Name: product; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA product;


--
-- Name: sales; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sales;


--
-- Name: support; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA support;


--
-- Name: access_level_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.access_level_enum AS ENUM (
    'Public',
    'Internal',
    'Confidential',
    'Restricted',
    'Secret',
    'TopSecret'
);


--
-- Name: approval_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.approval_status_enum AS ENUM (
    'pending',
    'submitted',
    'approved',
    'rejected',
    'reopened',
    'escalated',
    'withdrawn'
);


--
-- Name: clearance_level_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.clearance_level_enum AS ENUM (
    'Public',
    'Internal',
    'Confidential',
    'Secret',
    'TopSecret'
);


--
-- Name: composition_mode_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.composition_mode_enum AS ENUM (
    'PERMISSIVE',
    'RESTRICTIVE'
);


--
-- Name: contract_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.contract_status_enum AS ENUM (
    'Pending',
    'Approved',
    'Disputed',
    'Active',
    'Archived'
);


--
-- Name: deal_stage_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.deal_stage_enum AS ENUM (
    'Prospect',
    'Qualified',
    'Proposal',
    'Negotiation',
    'ClosedWon',
    'ClosedLost'
);


--
-- Name: document_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.document_type_enum AS ENUM (
    'Public',
    'Internal',
    'Confidential',
    'Secret',
    'TopSecret',
    'Restricted',
    'Regulated'
);


--
-- Name: environment_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.environment_type_enum AS ENUM (
    'Development',
    'Staging',
    'Production'
);


--
-- Name: feedback_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.feedback_type_enum AS ENUM (
    'Bug',
    'FeatureRequest',
    'CustomerIssue',
    'Inquiry',
    'Praise',
    'Complaint'
);


--
-- Name: issue_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.issue_status_enum AS ENUM (
    'open',
    'in_progress',
    'ready_for_qa',
    'resolved',
    'Archived',
    'Recorded'
);


--
-- Name: job_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.job_role_enum AS ENUM (
    'engineer',
    'senior_engineer',
    'junior_engineer',
    'qa_engineer',
    'devops_engineer',
    'manager',
    'dept_manager',
    'project_manager',
    'operations_manager',
    'director',
    'regional_director',
    'product_director',
    'vp_engineering',
    'vp_sales',
    'ceo',
    'cfo',
    'coo',
    'division_executive',
    'hr_specialist',
    'hr_admin',
    'accountant',
    'finance_analyst',
    'finance_manager',
    'tax_specialist',
    'procurement_officer',
    'security_analyst',
    'security_admin',
    'compliance_officer',
    'auditor',
    'risk_manager',
    'sales_rep',
    'sales_manager',
    'account_manager',
    'product_manager',
    'designer',
    'customer_support',
    'admin',
    'guest',
    'readonly_user',
    'data_analyst',
    'build_admin',
    'build_engineer',
    'ehs_officer',
    'sustainability_officer',
    'workplace_coordinator',
    'manufacturing_engineer',
    'customer_advocacy_manager',
    'staff_augmentation_coordinator',
    'siem_admin',
    'secops_engineer',
    'appsec_engineer',
    'iam_admin',
    'sre',
    'dba',
    'audit_lead',
    'engineering_manager',
    'qa_lead',
    'privacy_officer',
    'network_admin',
    'call_center_supervisor',
    'derogation_manager',
    'infra_admin',
    'support_ops'
);


--
-- Name: TYPE job_role_enum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.job_role_enum IS '
Allowed values for app.job_role (63 values).
Core engineering: engineer, senior_engineer, junior_engineer, qa_engineer, devops_engineer, build_engineer, manufacturing_engineer, sre, dba.
Management: manager, dept_manager, project_manager, operations_manager, engineering_manager, qa_lead, workplace_coordinator, staff_augmentation_coordinator.
Leadership: director, regional_director, vp_engineering, vp_sales, ceo, cfo, coo, division_executive.
HR: hr_specialist, hr_admin.
Finance: accountant, finance_analyst, finance_manager, tax_specialist, procurement_officer.
Security/compliance: security_analyst, security_admin, secops_engineer, appsec_engineer, iam_admin, infra_admin, network_admin, siem_admin, compliance_officer, auditor, audit_lead, risk_manager, privacy_officer.
Sales: sales_rep, sales_manager, account_manager.
Product/customer: product_manager, product_director, designer, customer_support, customer_advocacy_manager.
Facilities/EHS: ehs_officer, sustainability_officer.
Special/session: admin, guest, readonly_user, data_analyst, build_admin, call_center_supervisor, derogation_manager, support_ops.
';


--
-- Name: payment_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_status_enum AS ENUM (
    'Pending',
    'Paid',
    'Unpaid',
    'Overdue'
);


--
-- Name: policy_command_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.policy_command_enum AS ENUM (
    'SELECT',
    'INSERT',
    'UPDATE',
    'DELETE',
    'ALL'
);


--
-- Name: policy_mode_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.policy_mode_enum AS ENUM (
    'PERMISSIVE',
    'RESTRICTIVE'
);


--
-- Name: record_state_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.record_state_enum AS ENUM (
    'Draft',
    'Active',
    'Archived',
    'Deleted',
    'Frozen',
    'Reopened'
);


--
-- Name: severity_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.severity_enum AS ENUM (
    'Low',
    'Medium',
    'High',
    'Critical'
);




CREATE FUNCTION auth.set_row_metadata() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at := CURRENT_TIMESTAMP;
        NEW.row_version := COALESCE(OLD.row_version, 0) + 1;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: capture_sensitive_row_change(); Type: FUNCTION; Schema: operations; Owner: -
--

CREATE FUNCTION operations.capture_sensitive_row_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_json jsonb;
    old_json jsonb;
    tenant_value integer;
    entity_value text;
BEGIN
    new_json := CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END;
    old_json := CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END;
    tenant_value := COALESCE((new_json ->> 'tenant_id')::integer, (old_json ->> 'tenant_id')::integer, 1);
    entity_value := COALESCE(
        new_json ->> 'employee_id', old_json ->> 'employee_id',
        new_json ->> 'payroll_id', old_json ->> 'payroll_id',
        new_json ->> 'account_id', old_json ->> 'account_id',
        new_json ->> 'event_id', old_json ->> 'event_id',
        new_json ->> 'contract_id', old_json ->> 'contract_id'
    );

    INSERT INTO operations.entity_audit_events (
        tenant_id, actor_employee_id, action, entity_schema, entity_table,
        entity_id, old_values, new_values, created_at
    ) VALUES (
        tenant_value,
        NULLIF(current_setting('app.employee_id', true), '')::integer,
        TG_OP,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        entity_value,
        old_json,
        new_json,
        CURRENT_TIMESTAMP
    );

    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;


--
-- Name: init_employee_session(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.init_employee_session(p_employee_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_user_id integer;
  v_job_role text;
  v_department_id integer;
  v_team_id integer;
  v_region_id integer;
  v_user_clearance_level integer;
  v_position_level integer;
  v_tenant_id integer;
BEGIN
  SELECT
    u.user_id,
    COALESCE(e.current_job_role, e.job_role, 'employee'),
    COALESCE(e.department_id, 1),
    COALESCE(e.team_id, 1),
    COALESCE(e.region_id, 1),
    COALESCE(
      CASE
        WHEN NULLIF(e.user_clearance_level, '') ~ '^[0-9]+$' THEN e.user_clearance_level::integer
        WHEN lower(NULLIF(e.user_clearance_level, '')) IN ('top_secret', 'topsecret') THEN 5
        WHEN lower(NULLIF(e.user_clearance_level, '')) = 'secret' THEN 4
        WHEN lower(NULLIF(e.user_clearance_level, '')) = 'confidential' THEN 3
        WHEN lower(NULLIF(e.user_clearance_level, '')) = 'internal' THEN 2
        WHEN lower(NULLIF(e.user_clearance_level, '')) = 'public' THEN 1
        ELSE NULL
      END,
      e.security_clearance,
      1
    ),
    COALESCE(e.position_level, 1),
    COALESCE(e.tenant_id, 1)
  INTO
    v_user_id,
    v_job_role,
    v_department_id,
    v_team_id,
    v_region_id,
    v_user_clearance_level,
    v_position_level,
    v_tenant_id
  FROM hr.employees e
  LEFT JOIN auth.users u ON u.employee_id = e.employee_id
  WHERE e.employee_id = p_employee_id
  ORDER BY u.user_id
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee ID % not found', p_employee_id;
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No auth.users row is mapped to employee ID %', p_employee_id;
  END IF;

  PERFORM public.init_rls_session(
    p_employee_id,
    v_user_id,
    v_job_role,
    v_department_id,
    v_team_id,
    v_region_id,
    v_user_clearance_level,
    v_position_level,
    v_tenant_id,
    NULL
  );
END;
$$;


--
-- Name: FUNCTION init_employee_session(p_employee_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.init_employee_session(p_employee_id integer) IS 'Initializes supported Text2RLS session attributes by loading employee metadata from hr.employees and the mapped account id from auth.users. Customer identity is only set by init_rls_session when p_customer_id is supplied.';


--
-- Name: init_rls_session(integer, integer, text, integer, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.init_rls_session(p_employee_id integer DEFAULT 1, p_user_id integer DEFAULT NULL::integer, p_job_role text DEFAULT 'employee'::text, p_department_id integer DEFAULT 1, p_team_id integer DEFAULT 1, p_region_id integer DEFAULT 1, p_user_clearance_level integer DEFAULT 1, p_position_level integer DEFAULT 1, p_tenant_id integer DEFAULT 1, p_customer_id integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM set_config('app.employee_id', p_employee_id::text, false);
  PERFORM set_config('app.user_id', COALESCE(p_user_id, p_employee_id)::text, false);
  PERFORM set_config('app.job_role', p_job_role, false);
  PERFORM set_config('app.department_id', p_department_id::text, false);
  PERFORM set_config('app.team_id', p_team_id::text, false);
  PERFORM set_config('app.region_id', p_region_id::text, false);
  PERFORM set_config('app.user_clearance_level', p_user_clearance_level::text, false);
  PERFORM set_config('app.position_level', p_position_level::text, false);
  PERFORM set_config('app.tenant_id', p_tenant_id::text, false);

  IF p_customer_id IS NOT NULL THEN
    PERFORM set_config('app.customer_id', p_customer_id::text, false);
  END IF;
END;
$$;


--
-- Name: FUNCTION init_rls_session(p_employee_id integer, p_user_id integer, p_job_role text, p_department_id integer, p_team_id integer, p_region_id integer, p_user_clearance_level integer, p_position_level integer, p_tenant_id integer, p_customer_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.init_rls_session(p_employee_id integer, p_user_id integer, p_job_role text, p_department_id integer, p_team_id integer, p_region_id integer, p_user_clearance_level integer, p_position_level integer, p_tenant_id integer, p_customer_id integer) IS 'Initializes the supported Text2RLS session attributes: app.employee_id, app.user_id, app.job_role, app.department_id, app.team_id, app.region_id, app.user_clearance_level, app.position_level, app.tenant_id, and optional app.customer_id.';





--
-- Name: FUNCTION is_business_hours(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.is_business_hours() IS 'Check if current time is within business hours, excluding holidays';



COMMENT ON FUNCTION public.is_business_hours_at(check_timestamp timestamp without time zone) IS 'Check if specified timestamp is within business hours';


--
-- Name: safe_current_setting(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.safe_current_setting(setting_name text, default_value text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting(setting_name);
EXCEPTION
    WHEN undefined_object THEN
        RETURN default_value;
END;
$$;


--
-- Name: FUNCTION safe_current_setting(setting_name text, default_value text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.safe_current_setting(setting_name text, default_value text) IS '安全地获取配置参数，不存在时返回默认值';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_grants; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.access_grants (
    grant_id integer NOT NULL,
    user_id integer NOT NULL,
    target_tenant_id integer NOT NULL,
    target_schema text,
    target_table text,
    can_read boolean DEFAULT false NOT NULL,
    can_update boolean DEFAULT false NOT NULL,
    support_case boolean DEFAULT false NOT NULL,
    emergency_override boolean DEFAULT false NOT NULL,
    incident_response boolean DEFAULT false NOT NULL,
    data_review boolean DEFAULT false NOT NULL,
    case_review boolean DEFAULT false NOT NULL,
    financial_review boolean DEFAULT false NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    approved_by integer,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE access_grants; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.access_grants IS 'Temporary access grants scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN access_grants.user_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';

COMMENT ON COLUMN auth.access_grants.can_read IS 'Grant permits read access to the target table and tenant.';
COMMENT ON COLUMN auth.access_grants.can_update IS 'Grant permits update access to the target table and tenant.';
COMMENT ON COLUMN auth.access_grants.support_case IS 'Grant was issued for a customer or support case.';
COMMENT ON COLUMN auth.access_grants.emergency_override IS 'Grant was issued for emergency override access.';
COMMENT ON COLUMN auth.access_grants.incident_response IS 'Grant was issued for incident response.';
COMMENT ON COLUMN auth.access_grants.data_review IS 'Grant was issued for data quality or analytics review.';
COMMENT ON COLUMN auth.access_grants.case_review IS 'Grant was issued for HR, operations, or customer case review.';
COMMENT ON COLUMN auth.access_grants.financial_review IS 'Grant was issued for finance review such as expense or invoice handling.';


--
-- Name: COLUMN access_grants.created_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN access_grants.tenant_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN access_grants.updated_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN access_grants.created_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN access_grants.updated_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN access_grants.deleted_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN access_grants.deleted_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN access_grants.row_version; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.access_grants.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: business_units; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.business_units (
    business_unit_id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    organization_id integer NOT NULL,
    business_unit_code text NOT NULL,
    business_unit_name text NOT NULL,
    parent_business_unit_id integer,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT business_units_status_ck CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'archived'::text, 'deleted'::text])))
);


--
-- Name: TABLE business_units; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.business_units IS 'Business units within an organization and tenant. Scope: tenant.';


--
-- Name: COLUMN business_units.business_unit_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: COLUMN business_units.tenant_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN business_units.organization_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN business_units.status; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN business_units.created_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN business_units.updated_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN business_units.created_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN business_units.updated_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN business_units.deleted_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN business_units.deleted_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN business_units.row_version; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.business_units.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: business_units_business_unit_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.business_units ALTER COLUMN business_unit_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME auth.business_units_business_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: organizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.organizations (
    organization_id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    organization_code text NOT NULL,
    organization_name text NOT NULL,
    parent_organization_id integer,
    organization_type text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT organizations_status_ck CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'archived'::text, 'deleted'::text])))
);


--
-- Name: TABLE organizations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.organizations IS 'Tenant-owned organization hierarchy. Scope: tenant.';


--
-- Name: COLUMN organizations.organization_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN organizations.tenant_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN organizations.status; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN organizations.created_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN organizations.updated_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN organizations.created_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN organizations.updated_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN organizations.deleted_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN organizations.deleted_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN organizations.row_version; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.organizations.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: organizations_organization_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.organizations ALTER COLUMN organization_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME auth.organizations_organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: table_scopes; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.table_scopes (
    schema_name text NOT NULL,
    table_name text NOT NULL,
    scope_type text NOT NULL,
    scope_column text,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT table_scopes_scope_type_check CHECK ((scope_type = ANY (ARRAY['tenant'::text, 'global'::text])))
);


--
-- Name: TABLE table_scopes; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.table_scopes IS 'Scope catalog describing tenant-scoped and global-scoped tables. Scope: global.';


--
-- Name: COLUMN table_scopes.created_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.table_scopes.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN table_scopes.updated_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.table_scopes.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN table_scopes.created_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.table_scopes.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN table_scopes.updated_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.table_scopes.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN table_scopes.deleted_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.table_scopes.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN table_scopes.deleted_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.table_scopes.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN table_scopes.row_version; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.table_scopes.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: tenant_memberships; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.tenant_memberships (
    membership_id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    user_id integer NOT NULL,
    employee_id integer,
    organization_id integer,
    business_unit_id integer,
    department_id integer,
    team_id integer,
    role_name text,
    membership_status text DEFAULT 'active'::text NOT NULL,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    left_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT tenant_memberships_status_ck CHECK ((membership_status = ANY (ARRAY['active'::text, 'inactive'::text, 'revoked'::text, 'deleted'::text])))
);


--
-- Name: TABLE tenant_memberships; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.tenant_memberships IS 'User-to-tenant and organization membership. Scope: tenant.';


--
-- Name: COLUMN tenant_memberships.tenant_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN tenant_memberships.user_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';


--
-- Name: COLUMN tenant_memberships.employee_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN tenant_memberships.organization_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN tenant_memberships.business_unit_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: COLUMN tenant_memberships.department_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN tenant_memberships.team_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN tenant_memberships.role_name; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.role_name IS 'Tenant membership role token. Prefer concrete values from public.job_role_enum; see the schema header job_role enum groups for coarse role categories.';


--
-- Name: COLUMN tenant_memberships.created_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN tenant_memberships.updated_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN tenant_memberships.created_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN tenant_memberships.updated_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN tenant_memberships.deleted_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN tenant_memberships.deleted_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN tenant_memberships.row_version; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenant_memberships.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: tenant_memberships_membership_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.tenant_memberships ALTER COLUMN membership_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME auth.tenant_memberships_membership_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tenants; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.tenants (
    tenant_id integer NOT NULL,
    tenant_code text NOT NULL,
    tenant_name text NOT NULL,
    legal_name text,
    status text DEFAULT 'active'::text NOT NULL,
    plan_type text,
    data_region text,
    compliance_tier text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT tenants_row_version_ck CHECK ((row_version >= 1)),
    CONSTRAINT tenants_status_ck CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'disabled'::text, 'deleted'::text])))
);


--
-- Name: TABLE tenants; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.tenants IS 'Global tenant registry. Scope: global.';


--
-- Name: COLUMN tenants.tenant_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN tenants.status; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN tenants.created_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN tenants.updated_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN tenants.created_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN tenants.updated_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN tenants.deleted_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN tenants.deleted_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN tenants.row_version; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.tenants.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: tenants_tenant_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.tenants ALTER COLUMN tenant_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME auth.tenants_tenant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    user_id integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    employee_id integer,
    username text NOT NULL,
    email text,
    identity_provider text DEFAULT 'local'::text NOT NULL,
    external_subject text,
    user_status text DEFAULT 'active'::text NOT NULL,
    mfa_enabled boolean DEFAULT false NOT NULL,
    last_login_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT users_status_ck CHECK ((user_status = ANY (ARRAY['active'::text, 'locked'::text, 'disabled'::text, 'deleted'::text])))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Application login identities scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN users.user_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';


--
-- Name: COLUMN users.tenant_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN users.employee_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN users.created_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN users.updated_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN users.created_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN users.updated_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN users.deleted_at; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN users.deleted_by; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN users.row_version; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.users ALTER COLUMN user_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME auth.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: regions; Type: TABLE; Schema: common; Owner: -
--

CREATE TABLE common.regions (
    region_id integer NOT NULL,
    region_name character varying(100) NOT NULL,
    region_code character varying(10),
    manager_id integer,
    parent_region_id integer,
    timezone character varying(50),
    country_codes text[],
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true
);


--
-- Name: TABLE regions; Type: COMMENT; Schema: common; Owner: -
--

COMMENT ON TABLE common.regions IS '区域表：存储业务区域信息，支持销售和运营';


--
-- Name: COLUMN regions.manager_id; Type: COMMENT; Schema: common; Owner: -
--

COMMENT ON COLUMN common.regions.manager_id IS '区域经理的员工ID';


--
-- Name: regions_region_id_seq; Type: SEQUENCE; Schema: common; Owner: -
--

CREATE SEQUENCE common.regions_region_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regions_region_id_seq; Type: SEQUENCE OWNED BY; Schema: common; Owner: -
--

ALTER SEQUENCE common.regions_region_id_seq OWNED BY common.regions.region_id;


--
-- Name: security_levels; Type: TABLE; Schema: common; Owner: -
--

CREATE TABLE common.security_levels (
    level_id integer NOT NULL,
    level_name character varying(50) NOT NULL,
    level_value integer NOT NULL,
    description text,
    color_code character varying(7),
    can_access_public boolean DEFAULT true,
    can_access_internal boolean DEFAULT false,
    can_access_confidential boolean DEFAULT false,
    can_access_secret boolean DEFAULT false,
    can_access_top_secret boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT security_levels_level_value_check CHECK (((level_value >= 1) AND (level_value <= 10)))
);


--
-- Name: TABLE security_levels; Type: COMMENT; Schema: common; Owner: -
--

COMMENT ON TABLE common.security_levels IS '安全等级定义表：定义数据分类和访问权限';


--
-- Name: security_levels_level_id_seq; Type: SEQUENCE; Schema: common; Owner: -
--

CREATE SEQUENCE common.security_levels_level_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: security_levels_level_id_seq; Type: SEQUENCE OWNED BY; Schema: common; Owner: -
--

ALTER SEQUENCE common.security_levels_level_id_seq OWNED BY common.security_levels.level_id;


--
-- Name: builds; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.builds (
    build_id integer NOT NULL,
    project_id integer,
    build_number text,
    status text,
    build_type text,
    triggered_by integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    success boolean DEFAULT false,
    artifacts_path text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    build_status text,
    release_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE builds; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.builds IS 'Build records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN builds.project_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.project_id IS 'Project identifier used by project hierarchy policies.';


--
-- Name: COLUMN builds.status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN builds.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN builds.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN builds.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN builds.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN builds.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN builds.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN builds.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN builds.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.builds.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: code_repository; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.code_repository (
    repo_id integer NOT NULL,
    repo_name text,
    owner_id integer NOT NULL,
    project_id integer,
    visibility text,
    required_clearance integer,
    allowed_roles text[],
    programming_languages text[],
    last_commit text,
    branch_protection boolean DEFAULT false,
    artifact_type text,
    artifact_category text,
    warehouse_id integer,
    status text,
    employee_id integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    design_type text,
    assigned_reviewer integer,
    classification text,
    commit_type text,
    review_type text,
    peer_review_status text,
    request_type text,
    component_type text,
    office_location text,
    review_status text,
    gpg_signature_valid boolean,
    security_check boolean,
    approved_license boolean DEFAULT false,
    license_category text,
    branch_protected boolean DEFAULT false,
    team_id integer,
    sensitivity_level integer,
    repo_status text,
    archived_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT code_repository_required_clearance_check CHECK (((required_clearance >= 1) AND (required_clearance <= 7)))
);


--
-- Name: TABLE code_repository; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.code_repository IS 'Repository records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN code_repository.owner_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.owner_id IS 'Canonical repository owner employee_id used by ownership-based RLS policies.';


--
-- Name: COLUMN code_repository.project_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.project_id IS 'Project identifier used by project hierarchy policies.';


--
-- Name: COLUMN code_repository.artifact_type; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.artifact_type IS 'Repository artifact type used by code repository access policies, such as inventory, Schema Design, Specification, Release Notes, Restricted IP, or Infrastructure.';


--
-- Name: COLUMN code_repository.artifact_category; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.artifact_category IS 'High-level repository artifact category, such as Integration.';


--
-- Name: COLUMN code_repository.status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN code_repository.employee_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN code_repository.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN code_repository.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN code_repository.team_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN code_repository.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN code_repository.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN code_repository.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN code_repository.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN code_repository.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN code_repository.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.code_repository.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: issues; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.issues (
    issue_id integer NOT NULL,
    title text,
    description text,
    status text,
    priority text,
    severity text,
    assignee_id integer,
    reporter_id integer,
    project_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    due_date date,
    labels text[],
    estimated_hours numeric(8,2),
    issue_type text,
    project_lead integer,
    day character varying(255),
    category character varying(50) DEFAULT 'active'::character varying,
    employee_id integer,
    resolution_date timestamp without time zone,
    assigned_qa integer,
    cap_manager integer,
    creation_date timestamp without time zone,
    discovery_date timestamp without time zone,
    issue_category text,
    last_test_date timestamp without time zone,
    patch_date timestamp without time zone,
    playbook_documented boolean DEFAULT false,
    playbook_tested boolean DEFAULT false,
    pm_id integer,
    remediation_sla_days integer,
    service_area text,
    engineering text,
    projects text,
    "time" character varying(100),
    oncall_assignment text,
    derogation_manager integer,
    nominator_id integer,
    incident_type text,
    owner_id integer,
    repo_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    ticket_number text
);


--
-- Name: TABLE issues; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.issues IS 'Issue and ticket records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN issues.status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN issues.project_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.project_id IS 'Project identifier used by project hierarchy policies.';


--
-- Name: COLUMN issues.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN issues.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN issues.employee_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN issues.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN issues.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN issues.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN issues.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN issues.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN issues.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.issues.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: pr_comments; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.pr_comments (
    comment_id integer NOT NULL,
    pr_id integer,
    author_id integer,
    content text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_resolved boolean DEFAULT false,
    issue_type character varying(50) DEFAULT 'code_review'::character varying NOT NULL,
    project_lead integer NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE pr_comments; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.pr_comments IS 'Pull-request comments scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN pr_comments.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN pr_comments.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN pr_comments.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN pr_comments.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN pr_comments.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN pr_comments.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN pr_comments.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN pr_comments.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pr_comments.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: pr_comments_comment_id_seq; Type: SEQUENCE; Schema: engineering; Owner: -
--

CREATE SEQUENCE engineering.pr_comments_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pr_comments_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: engineering; Owner: -
--

ALTER SEQUENCE engineering.pr_comments_comment_id_seq OWNED BY engineering.pr_comments.comment_id;


--
-- Name: projects; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.projects (
    project_id integer NOT NULL,
    project_name text,
    owner_id integer NOT NULL,
    department_id integer,
    status text,
    required_clearance integer,
    team_members integer[],
    geographic_restrictions text[],
    budget numeric(12,2),
    start_date date,
    end_date date,
    technology_stack text[],
    security_requirements text,
    approved_license boolean DEFAULT false,
    category character varying(50) DEFAULT 'active'::character varying,
    hire_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_public boolean DEFAULT false,
    doc_category text,
    action text,
    data_type text,
    document_type text,
    employee_id integer,
    item_type text,
    report_type text,
    resource_type text,
    warehouse_id integer,
    assessor_id integer,
    change_sensitivity text,
    classification text,
    commit_type text,
    component_type text,
    created_date timestamp without time zone,
    design_type text,
    downgrading boolean DEFAULT false,
    gpg_signature_valid boolean DEFAULT false,
    independent_approval boolean DEFAULT false,
    integrity_model text,
    license_expiry_date timestamp without time zone,
    license_key_verified boolean DEFAULT false,
    merge_status text,
    modification_integrity_level text,
    office_location text,
    on_leave boolean DEFAULT false,
    peer_review_status text,
    program_id integer,
    project_type text,
    repo_type text,
    review_type text,
    access_control_model text,
    approval_count integer,
    review_status text,
    security_check boolean DEFAULT false,
    security_label_assigned boolean DEFAULT false,
    security_model text,
    user_clearance_level text,
    temporal_access text,
    request_type text,
    pm_id integer,
    operations character varying(100),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    tech_writer integer,
    tia_owner integer,
    project_coordinator integer,
    runbook_owner integer,
    document_security_level text,
    user_integrity_level text,
    reviewer_id integer,
    parent_project_id integer,
    project_lead integer,
    project_status text,
    version_status text,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    organization_id integer DEFAULT 1,
    business_unit_id integer DEFAULT 1,
    project_code text,
    CONSTRAINT projects_required_clearance_check CHECK (((required_clearance >= 1) AND (required_clearance <= 7)))
);


--
-- Name: TABLE projects; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.projects IS 'Engineering projects scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN projects.project_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.project_id IS 'Project identifier used by project hierarchy policies.';


--
-- Name: COLUMN projects.department_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN projects.status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN projects.employee_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN projects.security_level; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.security_level IS 'Numeric security level used by clearance and ordinal RLS predicates.';


--
-- Name: COLUMN projects.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN projects.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN projects.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN projects.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN projects.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN projects.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN projects.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN projects.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: COLUMN projects.organization_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN projects.business_unit_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.projects.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: pull_requests; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.pull_requests (
    pr_id integer NOT NULL,
    repo_id integer,
    author_id integer,
    title character varying(255) NOT NULL,
    target_branch character varying(100) DEFAULT 'main'::character varying,
    status character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    merged_at timestamp without time zone,
    merged_by integer,
    reviewers integer[],
    merge_status text,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE pull_requests; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.pull_requests IS 'Pull requests scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN pull_requests.status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN pull_requests.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN pull_requests.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN pull_requests.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN pull_requests.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN pull_requests.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN pull_requests.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN pull_requests.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN pull_requests.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.pull_requests.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: pull_requests_pr_id_seq; Type: SEQUENCE; Schema: engineering; Owner: -
--

CREATE SEQUENCE engineering.pull_requests_pr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pull_requests_pr_id_seq; Type: SEQUENCE OWNED BY; Schema: engineering; Owner: -
--

ALTER SEQUENCE engineering.pull_requests_pr_id_seq OWNED BY engineering.pull_requests.pr_id;


--
-- Name: releases; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.releases (
    release_id integer NOT NULL,
    release_name text NOT NULL,
    release_version text NOT NULL,
    status text DEFAULT 'planned'::text NOT NULL,
    project_id integer,
    release_date timestamp without time zone,
    deployment_date timestamp without time zone,
    deployment_approved boolean DEFAULT false,
    approval_status text DEFAULT 'pending'::text,
    change_type text,
    patch_type text,
    product_owner integer,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    build_start_time timestamp without time zone,
    build_end_time timestamp without time zone,
    description text,
    target_environment text,
    release_status text,
    released_by integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE releases; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.releases IS 'Release records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN releases.status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN releases.project_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.project_id IS 'Project identifier used by project hierarchy policies.';


--
-- Name: COLUMN releases.approval_status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN releases.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN releases.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN releases.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN releases.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN releases.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN releases.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN releases.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN releases.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.releases.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: releases_release_id_seq; Type: SEQUENCE; Schema: engineering; Owner: -
--

CREATE SEQUENCE engineering.releases_release_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: releases_release_id_seq; Type: SEQUENCE OWNED BY; Schema: engineering; Owner: -
--

ALTER SEQUENCE engineering.releases_release_id_seq OWNED BY engineering.releases.release_id;


--
-- Name: tests; Type: TABLE; Schema: engineering; Owner: -
--

CREATE TABLE engineering.tests (
    test_id integer NOT NULL,
    test_name text,
    test_suite text,
    status text,
    execution_time numeric(12,2),
    last_run timestamp without time zone,
    project_id integer,
    test_type text,
    environment text,
    failure_reason text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    category character varying(50) DEFAULT 'active'::character varying,
    required_clearance integer DEFAULT 1,
    approval_status text,
    created_by integer,
    artifact_type text,
    assigned_developer integer,
    qa_reviewer integer,
    attestation_signature_valid boolean DEFAULT false,
    build_start_time timestamp without time zone,
    chain_of_custody_documented boolean DEFAULT false,
    change_type text,
    dependency_scan_status text,
    deployment_approved boolean DEFAULT false,
    deployment_date timestamp without time zone,
    patch_type text,
    product_owner integer,
    release_date timestamp without time zone,
    sbom_generated boolean DEFAULT false,
    sbom_valid boolean DEFAULT false,
    scan_timestamp timestamp without time zone,
    vuln_scan_passed boolean DEFAULT false,
    "time" character varying(100),
    build_end_time timestamp without time zone,
    release_id integer,
    owner_id integer,
    issue_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE tests; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON TABLE engineering.tests IS 'Test execution records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN tests.status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN tests.project_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.project_id IS 'Project identifier used by project hierarchy policies.';


--
-- Name: COLUMN tests.created_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN tests.approval_status; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN tests.qa_reviewer; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.qa_reviewer IS 'QA employee assigned to review or approve the test record; used for separation-of-duties policies with assigned_developer.';


--
-- Name: COLUMN tests.created_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN tests.tenant_id; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN tests.updated_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN tests.updated_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN tests.deleted_at; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN tests.deleted_by; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN tests.row_version; Type: COMMENT; Schema: engineering; Owner: -
--

COMMENT ON COLUMN engineering.tests.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: account_transactions; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.account_transactions (
    transaction_id integer NOT NULL,
    account_id integer,
    transaction_type character varying(20),
    amount numeric(15,2) NOT NULL,
    description text,
    transaction_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    category character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT account_transactions_transaction_type_check CHECK (((transaction_type)::text = ANY ((ARRAY['Deposit'::character varying, 'Withdrawal'::character varying, 'Transfer'::character varying, 'Payment'::character varying, 'Fee'::character varying])::text[])))
);


--
-- Name: TABLE account_transactions; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.account_transactions IS 'Bank-account transactions scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN account_transactions.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN account_transactions.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN account_transactions.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN account_transactions.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN account_transactions.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN account_transactions.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN account_transactions.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN account_transactions.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.account_transactions.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: account_transactions_transaction_id_seq; Type: SEQUENCE; Schema: finance; Owner: -
--

CREATE SEQUENCE finance.account_transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: finance; Owner: -
--

ALTER SEQUENCE finance.account_transactions_transaction_id_seq OWNED BY finance.account_transactions.transaction_id;


--
-- Name: balance_sheet; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.balance_sheet (
    record_id integer NOT NULL,
    account_name text,
    account_type text,
    balance numeric(15,2),
    period text,
    fiscal_year integer,
    category text,
    subcategory text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entry_date date,
    amount numeric,
    status character varying(20),
    region_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE balance_sheet; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.balance_sheet IS 'Balance-sheet entries scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN balance_sheet.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN balance_sheet.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN balance_sheet.status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN balance_sheet.region_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN balance_sheet.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN balance_sheet.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN balance_sheet.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN balance_sheet.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN balance_sheet.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN balance_sheet.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.balance_sheet.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: bank_accounts; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.bank_accounts (
    account_id integer NOT NULL,
    account_number character varying(20) NOT NULL,
    account_name character varying(100),
    department_id integer,
    account_type character varying(20),
    currency character varying(3) DEFAULT 'USD'::character varying,
    balance numeric(15,2) DEFAULT 0.00,
    status character varying(20) DEFAULT 'Active'::character varying,
    opened_date date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    account_status text,
    is_current boolean DEFAULT true,
    owner_id integer,
    region_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT bank_accounts_account_type_check CHECK (((account_type)::text = ANY ((ARRAY['Checking'::character varying, 'Savings'::character varying, 'Corporate'::character varying, 'Expense'::character varying])::text[]))),
    CONSTRAINT bank_accounts_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Frozen'::character varying, 'Closed'::character varying])::text[])))
);


--
-- Name: TABLE bank_accounts; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.bank_accounts IS 'Bank accounts scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN bank_accounts.department_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN bank_accounts.status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN bank_accounts.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN bank_accounts.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN bank_accounts.region_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN bank_accounts.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN bank_accounts.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN bank_accounts.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN bank_accounts.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN bank_accounts.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN bank_accounts.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.bank_accounts.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: bank_accounts_account_id_seq; Type: SEQUENCE; Schema: finance; Owner: -
--

CREATE SEQUENCE finance.bank_accounts_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_accounts_account_id_seq; Type: SEQUENCE OWNED BY; Schema: finance; Owner: -
--

ALTER SEQUENCE finance.bank_accounts_account_id_seq OWNED BY finance.bank_accounts.account_id;


--
-- Name: budget; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.budget (
    budget_id integer NOT NULL,
    department_id integer,
    fiscal_year integer,
    quarter text,
    category text,
    allocated_amount numeric(12,2),
    remaining_amount numeric(12,2),
    approval_level integer,
    approved_by integer,
    approval_date date,
    manager_id integer,
    month character varying(255),
    year character varying(255),
    grant_adm character varying(255),
    hour integer,
    region_id integer,
    budget_amount numeric,
    budget_cycle_active boolean DEFAULT true,
    budget_owner integer,
    budget_type text,
    business_unit text,
    forecast_date timestamp without time zone,
    data_class text,
    report_period text,
    status character varying(50) DEFAULT 'draft'::character varying,
    sensitivity integer DEFAULT 1,
    amount numeric,
    created_at timestamp without time zone DEFAULT now(),
    increase_amount numeric,
    cost_center_id integer,
    owner_id integer,
    submitted_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    organization_id integer DEFAULT 1,
    business_unit_id integer DEFAULT 1,
    CONSTRAINT budget_approval_level_check CHECK (((approval_level >= 1) AND (approval_level <= 5)))
);


--
-- Name: TABLE budget; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.budget IS 'Budget records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN budget.department_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN budget.dept_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.dept_id IS 'Legacy department alias retained for benchmark compatibility; prefer department_id in new schema design.';


--
-- Name: COLUMN budget.manager_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.manager_id IS 'Manager employee_id used for hierarchy and recursive policies.';


--
-- Name: COLUMN budget.region_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN budget.status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN budget.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN budget.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN budget.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN budget.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN budget.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN budget.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN budget.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN budget.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: COLUMN budget.organization_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN budget.business_unit_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.budget.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: expenses; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.expenses (
    expense_id integer NOT NULL,
    employee_id integer,
    department_id integer,
    category text,
    amount numeric(12,2),
    description text,
    expense_date date,
    receipt_required boolean DEFAULT true,
    approved_by integer,
    approval_date date,
    expense_type text,
    status text,
    year character varying(255),
    confidential_until timestamp without time zone,
    month integer,
    hour integer,
    dow integer,
    approval_status text,
    document_type text,
    manager_id integer,
    record_type text,
    tax_year integer,
    approver_id integer,
    cost_center_id integer,
    expense_amount numeric,
    integrity_verified boolean DEFAULT false,
    transaction_logged boolean DEFAULT false,
    approval_sequence integer,
    integrity_model text,
    expenses text,
    finance text,
    program_type text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    rejected_at timestamp without time zone,
    escalated boolean DEFAULT false,
    reopened_at timestamp without time zone,
    bank_account_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE expenses; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.expenses IS 'Expense records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN expenses.employee_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN expenses.department_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN expenses.status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN expenses.dept_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.dept_id IS 'Legacy department alias retained for benchmark compatibility; prefer department_id in new schema design.';


--
-- Name: COLUMN expenses.approval_status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN expenses.manager_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.manager_id IS 'Manager employee_id used for hierarchy and recursive policies.';


--
-- Name: COLUMN expenses.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN expenses.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN expenses.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN expenses.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN expenses.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN expenses.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN expenses.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN expenses.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.expenses.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: payroll; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.payroll (
    payroll_id integer NOT NULL,
    employee_id integer,
    department_id integer,
    position_level integer,
    base_salary numeric(12,2),
    bonus numeric(12,2),
    commission numeric(12,2),
    deductions numeric(12,2),
    net_pay numeric(12,2),
    pay_period_start date,
    pay_period_end date,
    pay_date date,
    payment_method text,
    tax_withheld numeric(12,2),
    benefits_contribution numeric(12,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_type text,
    is_current boolean DEFAULT true,
    status text,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE payroll; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.payroll IS 'Finance payroll records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN payroll.employee_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN payroll.department_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN payroll.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN payroll.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN payroll.status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN payroll.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN payroll.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN payroll.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN payroll.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN payroll.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN payroll.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.payroll.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: revenue; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.revenue (
    revenue_id integer NOT NULL,
    source text,
    department_id integer,
    amount numeric(12,2),
    revenue_date date,
    contract_id integer,
    customer_id integer,
    fiscal_period text,
    recognized boolean DEFAULT false,
    region_id integer,
    sensitivity character varying(50) DEFAULT 'internal'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    data_class text,
    data_period text,
    forecast_date timestamp without time zone,
    report_period text,
    is_current boolean DEFAULT true,
    owner_id integer,
    report_status text,
    status text,
    closed_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE revenue; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.revenue IS 'Revenue records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN revenue.department_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN revenue.customer_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN revenue.region_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN revenue.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN revenue.status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN revenue.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN revenue.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN revenue.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN revenue.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN revenue.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN revenue.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN revenue.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.revenue.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: tax_records; Type: TABLE; Schema: finance; Owner: -
--

CREATE TABLE finance.tax_records (
    tax_id integer NOT NULL,
    employee_id integer,
    tax_year integer,
    tax_type text,
    taxable_income numeric(15,2),
    tax_owed numeric(12,2),
    tax_paid numeric(12,2),
    filing_date date,
    due_date date,
    status text,
    tax_jurisdiction text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    document_type character varying(50) DEFAULT 'filing'::character varying,
    record_type text,
    owner_id integer,
    filed_at timestamp without time zone,
    vendor_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE tax_records; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON TABLE finance.tax_records IS 'Tax records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN tax_records.employee_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN tax_records.status; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN tax_records.created_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN tax_records.updated_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN tax_records.tenant_id; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN tax_records.created_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN tax_records.updated_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN tax_records.deleted_at; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN tax_records.deleted_by; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN tax_records.row_version; Type: COMMENT; Schema: finance; Owner: -
--

COMMENT ON COLUMN finance.tax_records.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: attendance; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.attendance (
    attendance_id integer NOT NULL,
    employee_id integer NOT NULL,
    work_date date,
    check_in timestamp without time zone,
    check_out timestamp without time zone,
    hours_worked numeric(5,2),
    overtime_hours numeric(5,2),
    break_duration numeric(5,2),
    status text,
    notes text,
    approved_by integer,
    approved_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    approval_status text,
    department_id integer,
    team_id integer,
    manager_id integer,
    record_type text,
    request_type text,
    shift_id integer,
    supervisor_id integer,
    employees text,
    hr text,
    is_team_lead boolean DEFAULT false,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE attendance; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.attendance IS 'Attendance and leave records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN attendance.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN attendance.status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN attendance.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN attendance.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN attendance.approval_status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN attendance.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN attendance.team_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN attendance.manager_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.manager_id IS 'Manager employee_id used for hierarchy and recursive policies.';


--
-- Name: COLUMN attendance.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN attendance.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN attendance.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN attendance.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN attendance.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN attendance.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.attendance.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: benefits; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.benefits (
    benefit_id integer NOT NULL,
    employee_id integer NOT NULL,
    benefit_type text,
    benefit_name text,
    coverage_amount numeric(12,2),
    employee_contribution numeric(10,2),
    employer_contribution numeric(10,2),
    coverage_start_date date,
    coverage_end_date date,
    status text,
    provider text,
    plan_type text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    enrollment_start date,
    enrollment_end date,
    record_type text,
    is_eligible boolean,
    benefits_adm character varying(255),
    leave_status character varying(50) DEFAULT 'active'::character varying,
    training_adm character varying(255),
    hire_date timestamp without time zone,
    benefit_category text,
    last_completion_date timestamp without time zone,
    program_type text,
    training_completion_date timestamp without time zone,
    training_type text,
    employees text,
    hr text,
    is_current boolean DEFAULT true,
    effective_date date,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE benefits; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.benefits IS 'Benefit enrollment records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN benefits.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN benefits.status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN benefits.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN benefits.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN benefits.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN benefits.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN benefits.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN benefits.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN benefits.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN benefits.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.benefits.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: departments; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.departments (
    department_id integer NOT NULL,
    department_name character varying(100) NOT NULL,
    manager_id integer,
    location character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    parent_department_id integer,
    region_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    organization_id integer DEFAULT 1,
    business_unit_id integer DEFAULT 1
);


--
-- Name: TABLE departments; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.departments IS 'Departments scoped to a tenant and organization. Scope: tenant.';


--
-- Name: COLUMN departments.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN departments.manager_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.manager_id IS 'Manager employee_id used for hierarchy and recursive policies.';


--
-- Name: COLUMN departments.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN departments.region_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN departments.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN departments.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN departments.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN departments.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN departments.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN departments.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN departments.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: COLUMN departments.organization_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN departments.business_unit_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.departments.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: hr; Owner: -
--

CREATE SEQUENCE hr.departments_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: hr; Owner: -
--

ALTER SEQUENCE hr.departments_department_id_seq OWNED BY hr.departments.department_id;


--
-- Name: employee_allowances; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.employee_allowances (
    allowance_id integer NOT NULL,
    employee_id integer,
    monthly_allowance numeric,
    effective_from date,
    effective_to date,
    approved_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    effective_date date,
    updated_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE employee_allowances; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.employee_allowances IS 'Employee allowance records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN employee_allowances.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN employee_allowances.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN employee_allowances.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN employee_allowances.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN employee_allowances.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN employee_allowances.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN employee_allowances.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN employee_allowances.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN employee_allowances.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employee_allowances.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: employees; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.employees (
    employee_id integer NOT NULL,
    first_name text,
    last_name text,
    email text,
    department_id integer,
    department_name text,
    position_level integer,
    security_clearance integer,
    manager_id integer,
    hire_date date,
    region_id integer,
    employment_type text,
    is_active boolean DEFAULT true,
    skills_array text[] DEFAULT '{}'::text[],
    certifications_array text[] DEFAULT '{}'::text[],
    project_access text[],
    data_type text,
    conflicting_role character varying(50) DEFAULT 'active'::character varying,
    job_role character varying(50) DEFAULT 'active'::character varying,
    leave_status character varying(50) DEFAULT 'active'::character varying,
    dow integer,
    team_id integer,
    is_team_lead boolean DEFAULT false,
    access_control_type text,
    account_type text,
    approval_status text,
    last_review_date timestamp without time zone,
    record_type text,
    status text,
    approver_confirmed boolean DEFAULT false,
    confidential boolean DEFAULT false,
    disabled_date timestamp without time zone,
    entitlement_review_overdue boolean DEFAULT false,
    evaluation_status text,
    exception_required boolean DEFAULT false,
    export_date timestamp without time zone,
    file_type text,
    group_membership_new text,
    group_type text,
    has_lowercase boolean DEFAULT false,
    has_numbers boolean DEFAULT false,
    has_special_chars boolean DEFAULT false,
    has_uppercase boolean DEFAULT false,
    hr_partner integer,
    is_sensitive boolean DEFAULT false,
    justification_documented boolean DEFAULT false,
    last_entitlement_review timestamp without time zone,
    last_login_date timestamp without time zone,
    max_admin_members integer,
    membership_count integer,
    nda_signature_date timestamp without time zone,
    nda_signed boolean DEFAULT false,
    posting_type text,
    record_status text,
    regular_account_required boolean DEFAULT false,
    request_date timestamp without time zone,
    retention_date timestamp without time zone,
    retention_period_elapsed boolean DEFAULT false,
    separation_date timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    user_clearance_level text,
    user_integrity_level text,
    account_last_used_date timestamp without time zone,
    account_status text,
    data_section text,
    program_type text,
    review_status text,
    password_length integer,
    request_type text,
    role_type text,
    "current_role" text,
    office_location character varying(50),
    role character varying(50),
    phone_number text,
    address text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    approval_level integer,
    mentor_id integer,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    organization_id integer DEFAULT 1,
    business_unit_id integer DEFAULT 1,
    employee_number text,
    CONSTRAINT employees_security_clearance_check CHECK (((security_clearance >= 1) AND (security_clearance <= 7)))
);


--
-- Name: TABLE employees; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.employees IS 'Employee master records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN employees.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN employees.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN employees.security_clearance; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.security_clearance IS 'Numeric clearance level for subject/object comparison policies.';


--
-- Name: COLUMN employees.manager_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.manager_id IS 'Manager employee_id used for hierarchy and recursive policies.';


--
-- Name: COLUMN employees.region_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN employees.dept_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.dept_id IS 'Legacy department alias retained for benchmark compatibility; prefer department_id in new schema design.';


--
-- Name: COLUMN employees.job_role; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.job_role IS 'Legacy free-text current job role for an employee. app.job_role sessions should use one token from public.job_role_enum; role families are documented on public.job_role_enum.';


--
-- Name: COLUMN employees.team_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN employees.approval_status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN employees.status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN employees.record_status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.record_status IS 'Current record lifecycle state; retained for benchmark predicates.';


--
-- Name: COLUMN employees.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN employees.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN employees.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN employees.current_job_role; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.current_job_role IS 'Current canonical HR role token for the employee when populated; app.job_role should use one value from public.job_role_enum.';


--
-- Name: COLUMN employees.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN employees.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN employees.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN employees.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN employees.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: COLUMN employees.organization_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN employees.business_unit_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.employees.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: job_history; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.job_history (
    history_id integer NOT NULL,
    employee_id integer,
    department_id integer,
    position_level integer,
    start_date date NOT NULL,
    end_date date,
    change_reason character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE job_history; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.job_history IS 'Employee job-history records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN job_history.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN job_history.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN job_history.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN job_history.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN job_history.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN job_history.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN job_history.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN job_history.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN job_history.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN job_history.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.job_history.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: job_history_history_id_seq; Type: SEQUENCE; Schema: hr; Owner: -
--

CREATE SEQUENCE hr.job_history_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: hr; Owner: -
--

ALTER SEQUENCE hr.job_history_history_id_seq OWNED BY hr.job_history.history_id;


--
-- Name: payroll; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.payroll (
    payroll_id integer NOT NULL,
    employee_id integer NOT NULL,
    department_id integer,
    position_level integer,
    manager_id integer,
    region_id integer,
    base_salary numeric(12,2),
    bonus numeric(12,2),
    commission numeric(12,2),
    total_compensation text,
    salary_confidentiality text,
    requires_approval boolean DEFAULT false,
    approved_by integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_current boolean DEFAULT true,
    job_role character varying(50) DEFAULT 'active'::character varying,
    dow integer,
    hour integer,
    month integer,
    year integer,
    batch_id integer,
    can_export boolean DEFAULT false,
    update_type text,
    employment_status text,
    termination_date timestamp without time zone,
    salary_band character varying(20),
    direct_deposit boolean DEFAULT true,
    data_type character varying(100),
    pay_period_end date NOT NULL,
    approval_status text,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE payroll; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.payroll IS 'HR payroll correction records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN payroll.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN payroll.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN payroll.manager_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.manager_id IS 'Manager employee_id used for hierarchy and recursive policies.';


--
-- Name: COLUMN payroll.region_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN payroll.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN payroll.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN payroll.dept_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.dept_id IS 'Legacy department alias retained for benchmark compatibility; prefer department_id in new schema design.';


--
-- Name: COLUMN payroll.approval_status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN payroll.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN payroll.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN payroll.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN payroll.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN payroll.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN payroll.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.payroll.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: performance; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.performance (
    review_id integer NOT NULL,
    employee_id integer NOT NULL,
    review_period text,
    review_date date,
    reviewer_id integer,
    overall_rating numeric(3,1),
    goals_achievement numeric(3,1),
    skills_development numeric(3,1),
    teamwork numeric(3,1),
    leadership numeric(3,1),
    comments text,
    development_plan text,
    next_review_date date,
    status text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    manager_id integer,
    plan_type text,
    career_coach_id integer,
    team_lead_id integer,
    review_status text,
    department_id integer,
    is_current boolean DEFAULT true,
    score numeric,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE performance; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.performance IS 'Performance review records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN performance.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN performance.status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN performance.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN performance.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN performance.manager_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.manager_id IS 'Manager employee_id used for hierarchy and recursive policies.';


--
-- Name: COLUMN performance.dept_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.dept_id IS 'Legacy department alias retained for benchmark compatibility; prefer department_id in new schema design.';


--
-- Name: COLUMN performance.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN performance.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN performance.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN performance.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN performance.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN performance.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN performance.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.performance.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: positions; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.positions (
    position_id integer NOT NULL,
    position_title character varying(100) NOT NULL,
    position_code character varying(20),
    job_level integer DEFAULT 1,
    department_id integer,
    min_salary numeric(12,2),
    max_salary numeric(12,2),
    required_clearance integer DEFAULT 1,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT positions_job_level_check CHECK (((job_level >= 1) AND (job_level <= 10)))
);


--
-- Name: TABLE positions; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.positions IS 'Position catalog scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN positions.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN positions.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN positions.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN positions.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN positions.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN positions.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN positions.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN positions.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN positions.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.positions.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: positions_position_id_seq; Type: SEQUENCE; Schema: hr; Owner: -
--

CREATE SEQUENCE hr.positions_position_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: positions_position_id_seq; Type: SEQUENCE OWNED BY; Schema: hr; Owner: -
--

ALTER SEQUENCE hr.positions_position_id_seq OWNED BY hr.positions.position_id;


--
-- Name: salary_history; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.salary_history (
    history_id integer NOT NULL,
    employee_id integer,
    base_salary numeric(12,2),
    bonus numeric(12,2),
    currency character varying(3) DEFAULT 'USD'::character varying,
    effective_date date NOT NULL,
    end_date date,
    change_reason character varying(100),
    approved_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    is_current boolean DEFAULT true,
    status text,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE salary_history; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.salary_history IS 'Salary history scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN salary_history.employee_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN salary_history.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN salary_history.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN salary_history.status; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN salary_history.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN salary_history.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN salary_history.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN salary_history.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN salary_history.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN salary_history.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.salary_history.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: salary_history_history_id_seq; Type: SEQUENCE; Schema: hr; Owner: -
--

CREATE SEQUENCE hr.salary_history_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: salary_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: hr; Owner: -
--

ALTER SEQUENCE hr.salary_history_history_id_seq OWNED BY hr.salary_history.history_id;


--
-- Name: shifts; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.shifts (
    shift_id integer NOT NULL,
    shift_name character varying(50) NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_default boolean DEFAULT false,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true,
    department_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE shifts; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.shifts IS 'Shift definitions scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN shifts.shift_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.shift_id IS 'Unique shift identifier';


--
-- Name: COLUMN shifts.shift_name; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.shift_name IS 'Name of the shift (e.g., Day Shift, Night Shift)';


--
-- Name: COLUMN shifts.start_time; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.start_time IS 'Shift start time';


--
-- Name: COLUMN shifts.end_time; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.end_time IS 'Shift end time';


--
-- Name: COLUMN shifts.is_default; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.is_default IS 'Whether this is the default shift for business hours';


--
-- Name: COLUMN shifts.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN shifts.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN shifts.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN shifts.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN shifts.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN shifts.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN shifts.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN shifts.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN shifts.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.shifts.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: shifts_shift_id_seq; Type: SEQUENCE; Schema: hr; Owner: -
--

CREATE SEQUENCE hr.shifts_shift_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shifts_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: hr; Owner: -
--

ALTER SEQUENCE hr.shifts_shift_id_seq OWNED BY hr.shifts.shift_id;


--
-- Name: teams; Type: TABLE; Schema: hr; Owner: -
--

CREATE TABLE hr.teams (
    team_id integer NOT NULL,
    team_name character varying(100) NOT NULL,
    department_id integer,
    team_lead_id integer,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    organization_id integer DEFAULT 1,
    business_unit_id integer DEFAULT 1
);


--
-- Name: TABLE teams; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON TABLE hr.teams IS 'Teams scoped to a tenant and department. Scope: tenant.';


--
-- Name: COLUMN teams.team_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN teams.department_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN teams.team_lead_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.team_lead_id IS '团队领导的员工ID';


--
-- Name: COLUMN teams.created_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN teams.tenant_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN teams.updated_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN teams.created_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN teams.updated_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN teams.deleted_at; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN teams.deleted_by; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN teams.row_version; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: COLUMN teams.organization_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN teams.business_unit_id; Type: COMMENT; Schema: hr; Owner: -
--

COMMENT ON COLUMN hr.teams.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: teams_team_id_seq; Type: SEQUENCE; Schema: hr; Owner: -
--

CREATE SEQUENCE hr.teams_team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_team_id_seq; Type: SEQUENCE OWNED BY; Schema: hr; Owner: -
--

ALTER SEQUENCE hr.teams_team_id_seq OWNED BY hr.teams.team_id;


--
-- Name: audit_logs; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.audit_logs (
    log_id integer NOT NULL,
    employee_id integer,
    action text,
    table_name text,
    record_id integer,
    logged_at timestamp without time zone,
    ip_address text,
    user_agent text,
    session_id text,
    record_type text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    log_type text,
    archived boolean,
    audit_status text,
    confidentiality_level text,
    evidence_status text,
    incident_id integer,
    export_size bigint,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE audit_logs; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.audit_logs IS 'Operational audit logs scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN audit_logs.employee_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.employee_id IS 'Employee who performed the audited action; aligns with app.employee_id session context.';


--
-- Name: COLUMN audit_logs.action; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.action IS 'Specific audited action, such as api_call, Data Export, or Movement.';


--
-- Name: COLUMN audit_logs.logged_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.logged_at IS 'Timestamp when the audited event occurred or was recorded; distinct from row created_at.';


--
-- Name: COLUMN audit_logs.record_type; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.record_type IS 'Specific audited record or evidence type, such as Evidence, Legal Hold, or Mediation.';


--
-- Name: COLUMN audit_logs.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.created_at IS 'Timestamp when the row was created; RLS time predicates should prefer logged_at for event time.';


--
-- Name: COLUMN audit_logs.log_type; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.log_type IS 'Broad audit log category, such as Access, Audit, or Compliance.';


--
-- Name: COLUMN audit_logs.archived; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.archived IS 'Whether the audit log has been archived for retention lifecycle policies.';


--
-- Name: COLUMN audit_logs.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN audit_logs.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN audit_logs.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN audit_logs.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN audit_logs.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN audit_logs.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN audit_logs.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.audit_logs.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: backups; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.backups (
    backup_id integer NOT NULL,
    backup_type text,
    database_name text,
    backup_path text,
    backup_size_bytes bigint,
    compression_ratio numeric(5,2),
    encryption_status text,
    initiated_by integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    backup_status text,
    retention_days integer,
    verification_status text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    test_type text,
    documentation_required boolean,
    restore_approved boolean DEFAULT false,
    restore_requested_at timestamp without time zone,
    restored_at timestamp without time zone,
    software_type text,
    license_key_verified boolean DEFAULT false,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE backups; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.backups IS 'Backup records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN backups.backup_status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.backup_status IS 'Current backup lifecycle status, such as failed, restored, completed, or archived. Verification outcome is stored separately in verification_status.';


--
-- Name: COLUMN backups.verification_status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.verification_status IS 'Result of backup verification or restore validation, such as failed, verified, pending, or not_checked.';


--
-- Name: COLUMN backups.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN backups.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN backups.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN backups.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN backups.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN backups.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN backups.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN backups.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.backups.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: business_hours_config; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.business_hours_config (
    config_id integer NOT NULL,
    config_name character varying(100) NOT NULL,
    working_days integer[] DEFAULT ARRAY[1, 2, 3, 4, 5] NOT NULL,
    default_shift_id integer,
    exclude_holidays boolean DEFAULT true,
    country_code character varying(10) DEFAULT 'US'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE business_hours_config; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.business_hours_config IS 'Business-hours rules scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN business_hours_config.working_days; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.working_days IS 'Array of working days (1=Monday, 7=Sunday)';


--
-- Name: COLUMN business_hours_config.exclude_holidays; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.exclude_holidays IS 'Whether to exclude holidays from business hours';


--
-- Name: COLUMN business_hours_config.country_code; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.country_code IS 'Country code for holiday filtering';


--
-- Name: COLUMN business_hours_config.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN business_hours_config.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN business_hours_config.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN business_hours_config.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN business_hours_config.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN business_hours_config.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN business_hours_config.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN business_hours_config.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.business_hours_config.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: business_hours_config_config_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

CREATE SEQUENCE operations.business_hours_config_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_hours_config_config_id_seq; Type: SEQUENCE OWNED BY; Schema: operations; Owner: -
--

ALTER SEQUENCE operations.business_hours_config_config_id_seq OWNED BY operations.business_hours_config.config_id;


--
-- Name: documents; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.documents (
    document_id integer NOT NULL,
    document_title text,
    document_type text,
    author_id integer,
    department_id integer,
    security_classification text,
    sensitivity_level integer,
    access_control_list integer[],
    denied_users integer[],
    required_clearance integer,
    document_status text,
    version_number text,
    file_path text,
    file_size_bytes integer,
    created_at timestamp without time zone,
    expires_at timestamp without time zone,
    is_encrypted boolean DEFAULT false,
    retention_policy text,
    geographic_restrictions text[],
    project_id integer,
    record_type character varying(50) DEFAULT 'general'::character varying NOT NULL,
    employee_id integer,
    request_type text,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    owner_id integer,
    item_type text,
    license_expiry_date timestamp without time zone,
    conflicting_role text,
    account_type text,
    permission_count integer,
    status text,
    published_at timestamp without time zone,
    system_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT chk_project_needs_department CHECK (((project_id IS NULL) OR (department_id IS NOT NULL))),
    CONSTRAINT documents_required_clearance_check CHECK (((required_clearance >= 1) AND (required_clearance <= 7))),
    CONSTRAINT documents_sensitivity_level_check CHECK (((sensitivity_level >= 1) AND (sensitivity_level <= 7)))
);


--
-- Name: TABLE documents; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.documents IS 'Operational documents scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN documents.department_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN documents.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN documents.project_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.project_id IS 'Project identifier used by project hierarchy policies.';


--
-- Name: COLUMN documents.employee_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN documents.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN documents.status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN documents.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN documents.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN documents.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN documents.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN documents.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN documents.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.documents.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: entity_approval_history; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.entity_approval_history (
    approval_history_id bigint NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    entity_schema text NOT NULL,
    entity_table text NOT NULL,
    entity_id text NOT NULL,
    approval_step integer,
    approval_status text NOT NULL,
    requested_by integer,
    approved_by integer,
    approved_at timestamp without time zone,
    comments text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT entity_approval_status_ck CHECK ((lower(approval_status) = ANY (ARRAY['pending'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'reopened'::text, 'escalated'::text, 'withdrawn'::text])))
);


--
-- Name: TABLE entity_approval_history; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.entity_approval_history IS 'Normalized approval history for workflows that also expose current approval fields in benchmark tables.';


--
-- Name: COLUMN entity_approval_history.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_approval_history.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN entity_approval_history.approval_status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_approval_history.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN entity_approval_history.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_approval_history.created_at IS 'Timestamp when the row was created.';


--
-- Name: entity_approval_history_approval_history_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

ALTER TABLE operations.entity_approval_history ALTER COLUMN approval_history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME operations.entity_approval_history_approval_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: entity_assignments; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.entity_assignments (
    assignment_id bigint NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    entity_schema text NOT NULL,
    entity_table text NOT NULL,
    entity_id text NOT NULL,
    assigned_to integer,
    assigned_team_id integer,
    assigned_by integer,
    assignment_status text DEFAULT 'active'::text NOT NULL,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    released_at timestamp without time zone,
    CONSTRAINT entity_assignments_status_ck CHECK ((assignment_status = ANY (ARRAY['active'::text, 'released'::text, 'revoked'::text, 'deleted'::text])))
);


--
-- Name: TABLE entity_assignments; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.entity_assignments IS 'Normalized assignment history for employees, teams, tickets, contracts, projects, and support records.';


--
-- Name: COLUMN entity_assignments.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_assignments.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: entity_assignments_assignment_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

ALTER TABLE operations.entity_assignments ALTER COLUMN assignment_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME operations.entity_assignments_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: entity_attachments; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.entity_attachments (
    attachment_id bigint NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    entity_schema text NOT NULL,
    entity_table text NOT NULL,
    entity_id text NOT NULL,
    file_name text NOT NULL,
    content_type text,
    storage_uri text NOT NULL,
    checksum_sha256 text,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TABLE entity_attachments; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.entity_attachments IS 'Normalized attachment metadata table for enterprise entities.';


--
-- Name: COLUMN entity_attachments.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_attachments.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN entity_attachments.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_attachments.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN entity_attachments.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_attachments.created_at IS 'Timestamp when the row was created.';


--
-- Name: entity_attachments_attachment_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

ALTER TABLE operations.entity_attachments ALTER COLUMN attachment_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME operations.entity_attachments_attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: entity_audit_events; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.entity_audit_events (
    audit_event_id bigint NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    actor_user_id integer,
    actor_employee_id integer,
    action text NOT NULL,
    entity_schema text NOT NULL,
    entity_table text NOT NULL,
    entity_id text,
    old_values jsonb,
    new_values jsonb,
    ip_address inet,
    user_agent text,
    request_id text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TABLE entity_audit_events; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.entity_audit_events IS 'Enterprise row-change audit log with tenant, actor, entity, old values, and new values.';


--
-- Name: COLUMN entity_audit_events.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_audit_events.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN entity_audit_events.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_audit_events.created_at IS 'Timestamp when the row was created.';


--
-- Name: entity_audit_events_audit_event_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

ALTER TABLE operations.entity_audit_events ALTER COLUMN audit_event_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME operations.entity_audit_events_audit_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: entity_notes; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.entity_notes (
    note_id bigint NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    entity_schema text NOT NULL,
    entity_table text NOT NULL,
    entity_id text NOT NULL,
    note_type text,
    note_body text NOT NULL,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TABLE entity_notes; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.entity_notes IS 'Normalized notes/comments table for enterprise entities.';


--
-- Name: COLUMN entity_notes.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_notes.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN entity_notes.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_notes.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN entity_notes.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_notes.created_at IS 'Timestamp when the row was created.';


--
-- Name: entity_notes_note_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

ALTER TABLE operations.entity_notes ALTER COLUMN note_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME operations.entity_notes_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: entity_status_history; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.entity_status_history (
    status_history_id bigint NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    entity_schema text NOT NULL,
    entity_table text NOT NULL,
    entity_id text NOT NULL,
    old_status text,
    new_status text NOT NULL,
    changed_by integer,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reason text
);


--
-- Name: TABLE entity_status_history; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.entity_status_history IS 'Normalized status history for business entities whose main tables keep current status for benchmark readability.';


--
-- Name: COLUMN entity_status_history.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.entity_status_history.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: entity_status_history_status_history_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

ALTER TABLE operations.entity_status_history ALTER COLUMN status_history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME operations.entity_status_history_status_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: holidays; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.holidays (
    holiday_id integer NOT NULL,
    holiday_name text,
    holiday_date date,
    country_code text,
    region text,
    holiday_type text,
    is_observed boolean DEFAULT false,
    business_impact text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    name character varying(50),
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE holidays; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.holidays IS 'Holiday calendars scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN holidays.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN holidays.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN holidays.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN holidays.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN holidays.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN holidays.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN holidays.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN holidays.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.holidays.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: security_events; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.security_events (
    event_id integer NOT NULL,
    event_type text,
    severity text,
    source_ip text,
    user_id integer,
    affected_resource text,
    event_description text,
    event_time timestamp without time zone,
    detection_method text,
    response_action text,
    resolved boolean DEFAULT false,
    resolved_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    monitoring_type text,
    archive_adm character varying(255),
    backup_adm character varying(255),
    certification_adm character varying(255),
    ethics_hotline_adm character varying(255),
    failed_log character varying(255),
    successful_log character varying(255),
    dow integer,
    incident_id integer,
    hour integer,
    month integer,
    year integer,
    dow_field integer,
    access_type text,
    account_privilege_level integer,
    action_type text,
    alert_response_time_sla integer,
    approval_required boolean DEFAULT true,
    data_sensitivity text,
    event_severity text,
    log_type text,
    logging_enabled boolean DEFAULT true,
    realtime_alert_enabled boolean DEFAULT false,
    record_type text,
    report_type text,
    status text,
    system_criticality text,
    test_type text,
    transfer_type text,
    alert_on_detection boolean DEFAULT false,
    alert_on_suspicious boolean DEFAULT false,
    anomaly_detection boolean DEFAULT false,
    anomaly_detection_enabled boolean DEFAULT false,
    archived boolean DEFAULT false,
    audit_required boolean DEFAULT false,
    audit_scope text,
    audit_status text,
    audit_type text,
    auto_alert_enabled boolean DEFAULT false,
    bulk_threshold_exceeded boolean DEFAULT false,
    case_type text,
    concurrent_sessions_limit integer,
    confidentiality_level text,
    deletion_approved boolean DEFAULT false,
    documentation_required boolean DEFAULT false,
    event_category text,
    event_section text,
    event_source text,
    evidence_status text,
    hold_type text,
    immutable_after_days integer,
    impossible_travel_check boolean DEFAULT false,
    incident_status text,
    incident_type text,
    location_deviation_detected boolean DEFAULT false,
    log_category text,
    log_destination text,
    logging_required boolean DEFAULT false,
    metadata_recorded boolean DEFAULT false,
    monitoring_enabled boolean DEFAULT false,
    multi_location_check boolean DEFAULT false,
    restore_approved boolean DEFAULT false,
    review_required boolean DEFAULT false,
    security_check boolean DEFAULT false,
    security_label_assigned boolean DEFAULT false,
    security_model text,
    siem_forwarding_enabled boolean DEFAULT false,
    source_ip_logged boolean DEFAULT false,
    source_location_logged boolean DEFAULT false,
    tamper_protection boolean DEFAULT false,
    threat_intel_enabled boolean DEFAULT false,
    threat_scan_passed boolean DEFAULT false,
    threshold_exceeded boolean DEFAULT false,
    tracking_type text,
    uba_enabled boolean DEFAULT false,
    verification_required boolean DEFAULT false,
    violation_detection_enabled boolean DEFAULT false,
    backup_time timestamp without time zone,
    permission_usage_analysis boolean DEFAULT false,
    session_type text,
    approval_documented boolean DEFAULT false,
    security_level integer,
    department_id integer,
    backup_date timestamp without time zone,
    employee_id integer,
    updated_at timestamp without time zone,
    requester_id integer NOT NULL,
    approval_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    supervisor_reviewed boolean DEFAULT false NOT NULL,
    supervisor_reviewer_id integer NOT NULL,
    hash_type text,
    salt_included boolean DEFAULT false,
    hash_length integer,
    policy_tested boolean DEFAULT false,
    last_test_date timestamp without time zone,
    break_glass_required boolean DEFAULT false,
    justification_mandatory boolean DEFAULT false,
    service_type text,
    min_password_length integer,
    complexity_required boolean DEFAULT false,
    api_protection boolean DEFAULT false,
    rate_limiting_enabled boolean DEFAULT false,
    quota_enforcement boolean DEFAULT false,
    triaged_at timestamp without time zone,
    config_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE security_events; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.security_events IS 'Security events scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN security_events.user_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';


--
-- Name: COLUMN security_events.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN security_events.dept_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.dept_id IS 'Legacy department alias retained for benchmark compatibility; prefer department_id in new schema design.';


--
-- Name: COLUMN security_events.status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN security_events.security_level; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.security_level IS 'Numeric security level used by clearance and ordinal RLS predicates.';


--
-- Name: COLUMN security_events.department_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN security_events.employee_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN security_events.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN security_events.approval_status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN security_events.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN security_events.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN security_events.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN security_events.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN security_events.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN security_events.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.security_events.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: sensitive_access_audit; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.sensitive_access_audit (
    sensitive_access_id bigint NOT NULL,
    tenant_id integer DEFAULT 1 NOT NULL,
    actor_user_id integer,
    actor_employee_id integer,
    target_schema text NOT NULL,
    target_table text NOT NULL,
    target_id text,
    access_reason text,
    access_purpose text,
    approved_by integer,
    ip_address inet,
    user_agent text,
    accessed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TABLE sensitive_access_audit; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.sensitive_access_audit IS 'Audit table for sensitive data reads such as payroll, bank accounts, employee records, security events, and contracts.';


--
-- Name: COLUMN sensitive_access_audit.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.sensitive_access_audit.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: sensitive_access_audit_sensitive_access_id_seq; Type: SEQUENCE; Schema: operations; Owner: -
--

ALTER TABLE operations.sensitive_access_audit ALTER COLUMN sensitive_access_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME operations.sensitive_access_audit_sensitive_access_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: system_config; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.system_config (
    config_id integer NOT NULL,
    config_key text,
    config_value text,
    config_type text,
    description text,
    is_encrypted boolean DEFAULT false,
    last_modified_at timestamp without time zone,
    effective_from timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    environment text,
    item_type text,
    access_type text,
    account_type text,
    approval_status text,
    maintenance_mode boolean DEFAULT false,
    api_access_enabled boolean DEFAULT true,
    updated_at timestamp without time zone,
    archived boolean DEFAULT false,
    effective_date date,
    inventory_type text,
    verification_type text,
    account_privilege_level text,
    last_rotation_date timestamp without time zone,
    last_review_date timestamp without time zone,
    transfer_type text,
    user_id integer,
    system_exposure text,
    cert_type text,
    service_criticality text,
    system_component text,
    key_type text,
    security_architecture text,
    access_control_principle text,
    recertification_required boolean,
    expiration_date timestamp without time zone,
    credential_storage text,
    failed_attempt_threshold text,
    employee_id integer,
    encryption_protocol text,
    firewall_type text,
    ddos_protection text,
    key_length integer,
    cert_pinning_enabled boolean,
    crypto_algorithm text,
    key_storage text,
    access_verification_required boolean,
    minimum_necessary_access boolean,
    auto_revoke boolean,
    encryption_enabled boolean,
    locked boolean DEFAULT false,
    mfa_enabled boolean DEFAULT false,
    attack_pattern_blocking boolean DEFAULT false,
    policy_version_current boolean DEFAULT true,
    lockout_duration_minutes integer DEFAULT 30,
    last_modified_by integer,
    effective_until date,
    enhanced_approval boolean DEFAULT false NOT NULL,
    expiration_time timestamp without time zone,
    approved_by integer,
    risk_level text,
    owner_id integer,
    documented boolean DEFAULT false,
    user_type text,
    vendor_id integer,
    last_used_date timestamp without time zone,
    last_password_rotation timestamp without time zone,
    password_history_count integer,
    reuse_prevention boolean DEFAULT false,
    status text,
    database_name text,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE system_config; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.system_config IS 'System configuration rows scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN system_config.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN system_config.approval_status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN system_config.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN system_config.user_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';


--
-- Name: COLUMN system_config.employee_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN system_config.status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN system_config.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN system_config.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN system_config.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN system_config.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN system_config.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN system_config.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.system_config.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: temporal_access; Type: TABLE; Schema: operations; Owner: -
--

CREATE TABLE operations.temporal_access (
    access_id integer NOT NULL,
    user_id integer,
    resource_type text,
    resource_id integer,
    access_level text,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    granted_by integer,
    grant_reason text,
    emergency_access boolean DEFAULT false,
    approval_required boolean DEFAULT true,
    approved_by integer,
    approved_at timestamp without time zone,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    allowed_operations character varying(255),
    api_gateway_adm character varying(255),
    approved_license boolean DEFAULT false,
    approved_system boolean DEFAULT false,
    category character varying(50) DEFAULT 'active'::character varying,
    conflicting_role character varying(50) DEFAULT 'active'::character varying,
    cross_orig character varying(255),
    crypto_algorithm character varying(255),
    device_id integer,
    encryption_protocol character varying(255),
    environment character varying(255),
    hire_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    key_type character varying(50) DEFAULT 'active'::character varying,
    permitted_op character varying(255),
    retention_years character varying(255),
    security_tool_type character varying(50) DEFAULT 'active'::character varying,
    session_timeout_30m timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sysadm character varying(255),
    system_access character varying(255),
    tls_version character varying(255),
    dow integer,
    month integer,
    year integer,
    cert_type text,
    key_length integer,
    expiration_date timestamp without time zone,
    cert_pinning_enabled boolean DEFAULT false,
    service_criticality text,
    firewall_type text,
    attack_pattern_blocking boolean DEFAULT false,
    system_exposure text,
    ddos_protection text DEFAULT 'disabled'::text,
    connection_type text,
    config_type text,
    last_review_date timestamp without time zone,
    config_section text,
    baseline_status text,
    account_privilege_level integer DEFAULT 1,
    mfa_enabled boolean DEFAULT false,
    access_control_principle text,
    minimum_necessary_access boolean DEFAULT true,
    system_criticality text,
    enhanced_approval boolean DEFAULT false,
    item_type text,
    last_rotation_date timestamp without time zone,
    api_type text,
    error_message_sanitization boolean DEFAULT false,
    sensitive_info_removal boolean DEFAULT false,
    account_type text,
    credential_storage text,
    last_password_rotation timestamp without time zone,
    permission_count integer,
    max_necessary_permissions integer,
    service_type text,
    min_password_length integer DEFAULT 8,
    complexity_required boolean DEFAULT false,
    password_history_count integer DEFAULT 0,
    reuse_prevention boolean DEFAULT false,
    failed_attempt_threshold integer DEFAULT 5,
    lockout_duration_minutes integer DEFAULT 30,
    security_architecture text,
    access_verification_required boolean DEFAULT false,
    policy_version_current boolean DEFAULT false,
    recertification_required boolean DEFAULT false,
    transfer_type text,
    key_storage text,
    device_approved boolean DEFAULT false,
    inventory_type text,
    setting_type text,
    verification_type text,
    country_id integer,
    documented boolean DEFAULT false,
    hour_field integer,
    access_type text,
    event_severity text,
    realtime_alert_enabled boolean DEFAULT false,
    alert_response_time_sla integer,
    approval_status text,
    data_sensitivity text,
    document_type text,
    access_control_model text,
    access_duration text,
    access_mode text,
    access_model text,
    access_scope text,
    account_status text,
    admin_override_enabled boolean DEFAULT false,
    allowed_origins_whitelist text,
    api_protection boolean DEFAULT false,
    approval_count integer,
    approval_documented boolean DEFAULT false,
    approval_sequence text,
    auto_revoke boolean DEFAULT false,
    backup_date timestamp without time zone,
    backup_time timestamp without time zone,
    batch_account_id integer,
    break_glass_required boolean DEFAULT false,
    cors_enabled boolean DEFAULT false,
    definition_type text,
    encryption_at_rest boolean DEFAULT false,
    encryption_enabled boolean DEFAULT false,
    encryption_in_transit boolean DEFAULT false,
    endpoint_type text,
    exception_type text,
    expiration_time timestamp without time zone,
    hash_length integer,
    hash_type text,
    inactivity_timeout integer,
    input_validation_enabled boolean DEFAULT false,
    intel_update_frequency_hours integer,
    justification_mandatory boolean DEFAULT false,
    last_used_date timestamp without time zone,
    locked_account boolean DEFAULT false,
    matrix_current boolean DEFAULT false,
    operation_sensitivity text,
    origin_type text,
    permission_usage_analysis boolean DEFAULT false,
    policy_tested boolean DEFAULT false,
    query_complexity_limit integer,
    query_depth_limit integer,
    quota_enforcement boolean DEFAULT false,
    rate_limiting_enabled boolean DEFAULT false,
    replication_type text,
    salt_included boolean DEFAULT false,
    schedule_type text,
    scope_restriction text,
    session_type text,
    software_type text,
    ssl_enabled boolean DEFAULT false,
    stepup_auth_completed boolean DEFAULT false,
    stepup_auth_timestamp timestamp without time zone,
    storage_location text,
    system_component text,
    termination_date timestamp without time zone,
    timeout_enforcement boolean DEFAULT false,
    validation_rules_defined boolean DEFAULT false,
    vendor_id integer,
    audit_required boolean DEFAULT false,
    data_section text,
    event_section text,
    last_test_date timestamp without time zone,
    license_expiry_date timestamp without time zone,
    threat_intel_enabled boolean DEFAULT false,
    user_type text,
    license_key_verified boolean DEFAULT false,
    employee_id integer,
    component_type text,
    effective_date date,
    "time" character varying(100),
    contract_end_date date,
    owner_id integer,
    status text,
    revoked_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE temporal_access; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON TABLE operations.temporal_access IS 'Temporal access rules scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN temporal_access.user_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';


--
-- Name: COLUMN temporal_access.created_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN temporal_access.updated_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN temporal_access.approval_status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN temporal_access.employee_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN temporal_access.status; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN temporal_access.tenant_id; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN temporal_access.created_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN temporal_access.updated_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN temporal_access.deleted_at; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN temporal_access.deleted_by; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN temporal_access.row_version; Type: COMMENT; Schema: operations; Owner: -
--

COMMENT ON COLUMN operations.temporal_access.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: analytics; Type: TABLE; Schema: product; Owner: -
--

CREATE TABLE product.analytics (
    analytic_id integer NOT NULL,
    metric_name text,
    metric_value numeric(15,2),
    metric_unit text,
    time_period text,
    product_id integer,
    category text,
    subcategory text,
    calculated_at timestamp without time zone,
    data_source text,
    confidence_level numeric(5,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    report_type text,
    data_type text,
    analytics_type text,
    campaign_manager integer,
    is_anonymized boolean,
    is_public boolean,
    subprocessor_manager integer,
    monitoring_type text,
    validation_type text,
    is_sensitive boolean,
    employee_id integer,
    updated_at timestamp without time zone,
    processor_type text,
    owner_id integer,
    status text,
    report_status text,
    published_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE analytics; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON TABLE product.analytics IS 'Product analytics scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN analytics.created_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN analytics.employee_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN analytics.updated_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN analytics.status; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN analytics.tenant_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN analytics.created_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN analytics.updated_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN analytics.deleted_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN analytics.deleted_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN analytics.row_version; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.analytics.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: feature_dependencies; Type: TABLE; Schema: product; Owner: -
--

CREATE TABLE product.feature_dependencies (
    dependency_id integer NOT NULL,
    feature_id integer NOT NULL,
    depends_on_feature_id integer NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE feature_dependencies; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON TABLE product.feature_dependencies IS 'Feature dependencies scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN feature_dependencies.created_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN feature_dependencies.tenant_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN feature_dependencies.updated_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN feature_dependencies.created_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN feature_dependencies.updated_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN feature_dependencies.deleted_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN feature_dependencies.deleted_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN feature_dependencies.row_version; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_dependencies.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: feature_dependencies_dependency_id_seq; Type: SEQUENCE; Schema: product; Owner: -
--

CREATE SEQUENCE product.feature_dependencies_dependency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feature_dependencies_dependency_id_seq; Type: SEQUENCE OWNED BY; Schema: product; Owner: -
--

ALTER SEQUENCE product.feature_dependencies_dependency_id_seq OWNED BY product.feature_dependencies.dependency_id;


--
-- Name: feature_usage; Type: TABLE; Schema: product; Owner: -
--

CREATE TABLE product.feature_usage (
    usage_id integer NOT NULL,
    feature_id integer NOT NULL,
    user_id integer,
    usage_count integer DEFAULT 0,
    last_active_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE feature_usage; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON TABLE product.feature_usage IS 'Feature usage scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN feature_usage.user_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';


--
-- Name: COLUMN feature_usage.created_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN feature_usage.tenant_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN feature_usage.updated_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN feature_usage.created_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN feature_usage.updated_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN feature_usage.deleted_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN feature_usage.deleted_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN feature_usage.row_version; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.feature_usage.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: feature_usage_usage_id_seq; Type: SEQUENCE; Schema: product; Owner: -
--

CREATE SEQUENCE product.feature_usage_usage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feature_usage_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: product; Owner: -
--

ALTER SEQUENCE product.feature_usage_usage_id_seq OWNED BY product.feature_usage.usage_id;


--
-- Name: features; Type: TABLE; Schema: product; Owner: -
--

CREATE TABLE product.features (
    feature_id integer NOT NULL,
    feature_name text,
    feature_description text,
    product_id integer,
    status text,
    effort_estimate numeric(8,2),
    business_value numeric(8,2),
    technical_complexity text,
    assigned_to integer,
    target_release_date date,
    actual_release_date date,
    dependencies text[],
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    visibility text,
    feedback_type text,
    category text,
    data_type text,
    item_type text,
    completion_date timestamp without time zone,
    content_type text,
    designer integer,
    employment_status text,
    escalation_level text,
    escalation_owner integer,
    feature_lead integer,
    is_verified boolean DEFAULT false,
    priority_status text,
    project_completed boolean DEFAULT false,
    roadmap_type text,
    supervisor_id integer,
    assessor_id integer,
    threat_scan_passed boolean DEFAULT false,
    sensitivity character varying(50) DEFAULT 'internal'::character varying,
    is_public boolean DEFAULT false,
    product_owner integer,
    mentor_id integer,
    instructor_id integer,
    employee_id integer,
    owner_id integer,
    team_id integer,
    released_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE features; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON TABLE product.features IS 'Feature catalog scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN features.status; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN features.created_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN features.updated_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN features.employee_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN features.team_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN features.tenant_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN features.created_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN features.updated_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN features.deleted_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN features.deleted_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN features.row_version; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.features.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: metrics; Type: TABLE; Schema: product; Owner: -
--

CREATE TABLE product.metrics (
    metric_id integer NOT NULL,
    metric_name text,
    metric_type text,
    current_value numeric(15,2),
    target_value numeric(15,2),
    unit text,
    product_id integer,
    owner_id integer,
    last_updated timestamp without time zone,
    trend text,
    alert_threshold numeric(5,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    metric_category text,
    is_anonymized boolean DEFAULT false,
    is_public boolean DEFAULT false,
    monitoring_type text,
    report_type text,
    aggregation_level text,
    assessment_date timestamp without time zone,
    data_class text,
    data_period text,
    data_section text,
    includes_security_metrics boolean DEFAULT false,
    metric_freshness text,
    processor_type text,
    review_season_end timestamp without time zone,
    review_season_start timestamp without time zone,
    scope text,
    subprocessor_manager integer,
    validation_type text,
    is_sensitive boolean DEFAULT false,
    store_id integer,
    account_id integer,
    cost_center_id integer,
    metric_owner integer,
    mitigation_owner integer,
    portfolio_manager integer,
    employee_id integer,
    student_id integer,
    updated_at timestamp without time zone,
    status text,
    validated_at timestamp without time zone,
    feature_id integer,
    team_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE metrics; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON TABLE product.metrics IS 'Product metrics scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN metrics.metric_type; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.metric_type IS 'Concrete metric type, such as Adoption, Utilization, Budget, Variance, Baseline, KPI, SLA, or Grade.';


--
-- Name: COLUMN metrics.created_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN metrics.metric_category; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.metric_category IS 'Broad metric category or business domain, such as Feature, Resource, Finance, Performance, Adoption, or System.';


--
-- Name: COLUMN metrics.report_type; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.report_type IS 'Report-oriented metric classification, used for budget and variance report access policies.';


--
-- Name: COLUMN metrics.employee_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN metrics.updated_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN metrics.status; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN metrics.team_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN metrics.tenant_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN metrics.created_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN metrics.updated_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN metrics.deleted_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN metrics.deleted_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN metrics.row_version; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.metrics.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: roadmap; Type: TABLE; Schema: product; Owner: -
--

CREATE TABLE product.roadmap (
    roadmap_id integer NOT NULL,
    item_name text,
    quarter text,
    status text,
    priority text,
    department_name text,
    estimated_effort integer,
    target_completion text,
    dependencies text[],
    security_impact text,
    item_type text,
    created_at timestamp without time zone DEFAULT now(),
    employee_id integer,
    owner_id integer,
    feature_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE roadmap; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON TABLE product.roadmap IS 'Roadmap items scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN roadmap.status; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN roadmap.item_type; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.item_type IS 'Normalized roadmap item category, such as strategic, technology, or strategic_plan. The roadmap table already scopes the row as a roadmap item, so there is no separate roadmap_type column.';


--
-- Name: COLUMN roadmap.created_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN roadmap.employee_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN roadmap.tenant_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN roadmap.updated_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN roadmap.created_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN roadmap.updated_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN roadmap.deleted_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN roadmap.deleted_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN roadmap.row_version; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.roadmap.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: user_feedback; Type: TABLE; Schema: product; Owner: -
--

CREATE TABLE product.user_feedback (
    feedback_id integer NOT NULL,
    user_id integer,
    product_id integer,
    feedback_text text,
    rating integer,
    submitted_at timestamp without time zone,
    category text,
    priority text,
    department_id integer,
    sensitivity_level integer,
    resolved boolean DEFAULT false,
    feedback_type text,
    data_type text,
    status text,
    escalation_owner integer,
    hiring_manager integer,
    employee_id integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    visibility text,
    escalation_level integer,
    assigned_to integer NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    feedback_status text,
    owner_id integer,
    resolved_at timestamp without time zone,
    customer_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    CONSTRAINT user_feedback_rating_check CHECK (((rating >= 1) AND (rating <= 5))),
    CONSTRAINT user_feedback_sensitivity_level_check CHECK (((sensitivity_level >= 1) AND (sensitivity_level <= 7)))
);


--
-- Name: TABLE user_feedback; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON TABLE product.user_feedback IS 'User feedback scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN user_feedback.user_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.user_id IS 'Application actor/user id; distinct from employee_id unless explicitly linked.';


--
-- Name: COLUMN user_feedback.department_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN user_feedback.status; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN user_feedback.employee_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN user_feedback.created_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN user_feedback.updated_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN user_feedback.customer_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN user_feedback.tenant_id; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN user_feedback.created_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN user_feedback.updated_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN user_feedback.deleted_at; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN user_feedback.deleted_by; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN user_feedback.row_version; Type: COMMENT; Schema: product; Owner: -
--

COMMENT ON COLUMN product.user_feedback.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: contracts; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.contracts (
    contract_id integer NOT NULL,
    customer_id integer NOT NULL,
    sales_rep_id integer,
    contract_value numeric(12,2),
    start_date date,
    end_date date,
    contract_type text,
    security_level integer,
    department_id integer,
    approval_required boolean DEFAULT true,
    legal_review boolean DEFAULT true,
    status text,
    contract_status text,
    shipment_status character varying(50) DEFAULT 'active'::character varying,
    dow integer,
    month integer,
    year integer,
    hour_field integer,
    account_manager integer,
    payment_status text DEFAULT 'pending'::text,
    payment_verified boolean DEFAULT false,
    created_by integer,
    team_id integer,
    region_id integer,
    customer_type text,
    expiration_date timestamp without time zone,
    fulfillment_status text,
    is_active boolean DEFAULT true,
    security_requirements text,
    transaction_type text,
    all_approvers_independent boolean DEFAULT false,
    assigned_region text,
    assigned_territory text,
    contact_type text,
    order_amount numeric,
    renewal_date timestamp without time zone,
    return_status text,
    review_status text,
    sales_rep integer,
    template_type text,
    transaction_criticality text,
    update_field text,
    vendor_contract boolean,
    version_status text,
    account_priority text,
    account_status text,
    approval_count integer,
    data_section text,
    split_part text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    partner_id integer,
    negotiator_id integer,
    processor_id integer,
    approver_level integer,
    employee_id integer,
    pipeline_stage text,
    fulfillment_stage text,
    approval_level integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    original_term_months integer,
    renewal_term_months integer,
    has_outstanding_disputes boolean DEFAULT false,
    approval_status text,
    approved_by integer,
    discount_percentage numeric,
    department_discount_threshold numeric,
    department_avg_contract_value numeric,
    vendor_id integer,
    account_manager_id integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    organization_id integer DEFAULT 1,
    business_unit_id integer DEFAULT 1,
    contract_number text,
    CONSTRAINT contracts_security_level_check CHECK (((security_level >= 1) AND (security_level <= 7)))
);


--
-- Name: TABLE contracts; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.contracts IS 'Sales contracts scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN contracts.customer_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN contracts.security_level; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.security_level IS 'Numeric security level used by clearance and ordinal RLS predicates.';


--
-- Name: COLUMN contracts.department_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN contracts.status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN contracts.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN contracts.team_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN contracts.region_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN contracts.vendor_contract; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.vendor_contract IS 'Whether the contract is a vendor/supplier contract.';


--
-- Name: COLUMN contracts.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN contracts.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN contracts.employee_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN contracts.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN contracts.approval_status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.approval_status IS 'Current approval state. Detailed approval steps should be stored in operations.entity_approval_history.';


--
-- Name: COLUMN contracts.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN contracts.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN contracts.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN contracts.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: COLUMN contracts.organization_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN contracts.business_unit_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.contracts.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: customer_communications; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.customer_communications (
    comm_id integer NOT NULL,
    customer_id integer,
    account_manager_id integer,
    engagement_manager_id integer,
    comm_type text,
    comm_direction text,
    subject text,
    occurred_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    communication_id integer,
    status text,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE customer_communications; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.customer_communications IS 'Customer communications scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN customer_communications.customer_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN customer_communications.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN customer_communications.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN customer_communications.status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN customer_communications.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN customer_communications.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN customer_communications.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN customer_communications.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN customer_communications.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN customer_communications.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_communications.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: customer_onboarding; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.customer_onboarding (
    onboarding_id integer NOT NULL,
    customer_id integer,
    onboarding_manager integer,
    progress_status text,
    status text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE customer_onboarding; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.customer_onboarding IS 'Customer onboarding records scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN customer_onboarding.customer_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN customer_onboarding.status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN customer_onboarding.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN customer_onboarding.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN customer_onboarding.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN customer_onboarding.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN customer_onboarding.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN customer_onboarding.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN customer_onboarding.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN customer_onboarding.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customer_onboarding.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: customers; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.customers (
    customer_id integer NOT NULL,
    customer_name text,
    contact_person text,
    contact_email text,
    industry text,
    customer_segment text,
    account_manager_id integer,
    region_id integer,
    contract_value numeric(12,2),
    security_clearance integer,
    data_sensitivity text,
    last_contact_date date,
    next_followup_date date,
    is_active boolean DEFAULT true,
    confidentiality_agreement text,
    geographic_data text[],
    customer_type text,
    name character varying(100),
    sensitivity integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    assigned_territory text,
    engagement_manager integer,
    vendor_compliance_officer integer,
    account_priority text,
    employee_id integer,
    job_role text,
    status text,
    activated_at timestamp without time zone,
    parent_customer_id integer,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL,
    organization_id integer DEFAULT 1,
    business_unit_id integer DEFAULT 1,
    customer_code text,
    CONSTRAINT customers_security_clearance_check CHECK (((security_clearance >= 1) AND (security_clearance <= 7)))
);


--
-- Name: TABLE customers; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.customers IS 'Customers scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN customers.customer_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN customers.region_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN customers.security_clearance; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.security_clearance IS 'Numeric clearance level for subject/object comparison policies.';


--
-- Name: COLUMN customers.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN customers.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN customers.employee_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN customers.status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN customers.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN customers.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN customers.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN customers.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN customers.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN customers.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: COLUMN customers.organization_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.organization_id IS 'Organization scope within a tenant.';


--
-- Name: COLUMN customers.business_unit_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.customers.business_unit_id IS 'Business-unit scope within a tenant and organization.';


--
-- Name: invoices; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.invoices (
    invoice_id integer NOT NULL,
    invoice_number text,
    customer_id integer NOT NULL,
    order_id integer,
    invoice_date date,
    due_date date,
    total_amount numeric(12,2),
    tax_amount numeric(12,2),
    discount_amount numeric(12,2),
    net_amount numeric(12,2),
    status text,
    payment_terms text,
    payment_date date,
    payment_method text,
    created_by integer,
    approved_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    payment_status text DEFAULT 'pending'::text,
    payment_verified boolean DEFAULT false,
    account_manager integer,
    employee_id integer,
    contract_id integer,
    paid_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE invoices; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.invoices IS 'Invoices scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN invoices.customer_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN invoices.status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN invoices.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN invoices.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN invoices.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN invoices.employee_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN invoices.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN invoices.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN invoices.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN invoices.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN invoices.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.invoices.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: orders; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.orders (
    order_id integer NOT NULL,
    customer_id integer NOT NULL,
    sales_rep_id integer,
    order_date date,
    total_amount numeric(12,2),
    contract_value numeric(12,2),
    status text,
    priority text,
    delivery_date date,
    payment_terms text,
    discount_percentage numeric(5,2),
    department_id integer,
    fulfillment_status text,
    created_at timestamp without time zone DEFAULT now(),
    region_id integer,
    shipment_status text,
    employee_id integer,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    contract_id integer,
    fulfilled_at timestamp without time zone,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE orders; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.orders IS 'Orders scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN orders.customer_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN orders.status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN orders.department_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.department_id IS 'Department scope used by enterprise access-control policies.';


--
-- Name: COLUMN orders.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN orders.region_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN orders.employee_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.employee_id IS 'HR employee identity anchor used by app.employee_id session policies.';


--
-- Name: COLUMN orders.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN orders.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN orders.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN orders.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN orders.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN orders.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN orders.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.orders.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: regions; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.regions (
    region_id integer NOT NULL,
    region_name text,
    parent_region_id integer,
    regional_director integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE regions; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.regions IS 'Sales regions scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN regions.region_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.region_id IS 'Geographic or sales-region scope used by regional policies.';


--
-- Name: COLUMN regions.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN regions.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN regions.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN regions.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN regions.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN regions.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN regions.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN regions.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.regions.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: sales_pipeline; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.sales_pipeline (
    pipeline_id integer NOT NULL,
    opportunity_name text,
    customer_id integer NOT NULL,
    sales_rep_id integer,
    team_id integer,
    stage text,
    probability numeric(5,2),
    estimated_value numeric(12,2),
    expected_close_date date,
    actual_close_date date,
    lead_source text,
    industry text,
    region text,
    competitors text[],
    next_action text,
    next_action_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sales_rep integer NOT NULL,
    account_manager_id integer,
    deal_value numeric,
    status text,
    tenant_id integer DEFAULT 1 NOT NULL,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sales_pipeline; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON TABLE sales.sales_pipeline IS 'Pipeline opportunities scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN sales_pipeline.customer_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN sales_pipeline.team_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN sales_pipeline.created_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN sales_pipeline.updated_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN sales_pipeline.status; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN sales_pipeline.tenant_id; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN sales_pipeline.created_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN sales_pipeline.updated_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN sales_pipeline.deleted_at; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN sales_pipeline.deleted_by; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN sales_pipeline.row_version; Type: COMMENT; Schema: sales; Owner: -
--

COMMENT ON COLUMN sales.sales_pipeline.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: call_recordings; Type: TABLE; Schema: support; Owner: -
--

CREATE TABLE support.call_recordings (
    recording_id integer NOT NULL,
    customer_id integer,
    agent_id integer,
    team_id integer,
    supervisor_id integer,
    call_start timestamp without time zone,
    call_duration_sec integer,
    recording_path text,
    recording_status text,
    consent_recorded boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT 1 NOT NULL,
    archived_at timestamp without time zone,
    status text,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    row_version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE call_recordings; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON TABLE support.call_recordings IS 'Support call recordings scoped to a tenant. Scope: tenant.';


--
-- Name: COLUMN call_recordings.customer_id; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.customer_id IS 'Customer/account identifier used by customer-scoped and tenant-scoped policies.';


--
-- Name: COLUMN call_recordings.team_id; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.team_id IS 'Team scope used by team-based access-control policies.';


--
-- Name: COLUMN call_recordings.created_at; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.created_at IS 'Timestamp when the row was created.';


--
-- Name: COLUMN call_recordings.tenant_id; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.tenant_id IS 'Tenant isolation key. Tenant-scoped rows must belong to auth.tenants.';


--
-- Name: COLUMN call_recordings.status; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.status IS 'Current lifecycle status. Detailed transitions should be stored in operations.entity_status_history.';


--
-- Name: COLUMN call_recordings.updated_at; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.updated_at IS 'Timestamp maintained by update triggers when the row changes.';


--
-- Name: COLUMN call_recordings.created_by; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.created_by IS 'Application user or employee that created the row, when known.';


--
-- Name: COLUMN call_recordings.updated_by; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.updated_by IS 'Application user or employee that last updated the row, when known.';


--
-- Name: COLUMN call_recordings.deleted_at; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.deleted_at IS 'Soft-delete timestamp; NULL means the row is active.';


--
-- Name: COLUMN call_recordings.deleted_by; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.deleted_by IS 'Application user or employee that soft-deleted the row, when known.';


--
-- Name: COLUMN call_recordings.row_version; Type: COMMENT; Schema: support; Owner: -
--

COMMENT ON COLUMN support.call_recordings.row_version IS 'Optimistic concurrency version incremented on update.';


--
-- Name: regions region_id; Type: DEFAULT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.regions ALTER COLUMN region_id SET DEFAULT nextval('common.regions_region_id_seq'::regclass);


--
-- Name: security_levels level_id; Type: DEFAULT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.security_levels ALTER COLUMN level_id SET DEFAULT nextval('common.security_levels_level_id_seq'::regclass);


--
-- Name: pr_comments comment_id; Type: DEFAULT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pr_comments ALTER COLUMN comment_id SET DEFAULT nextval('engineering.pr_comments_comment_id_seq'::regclass);


--
-- Name: pull_requests pr_id; Type: DEFAULT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pull_requests ALTER COLUMN pr_id SET DEFAULT nextval('engineering.pull_requests_pr_id_seq'::regclass);


--
-- Name: releases release_id; Type: DEFAULT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.releases ALTER COLUMN release_id SET DEFAULT nextval('engineering.releases_release_id_seq'::regclass);


--
-- Name: account_transactions transaction_id; Type: DEFAULT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.account_transactions ALTER COLUMN transaction_id SET DEFAULT nextval('finance.account_transactions_transaction_id_seq'::regclass);


--
-- Name: bank_accounts account_id; Type: DEFAULT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.bank_accounts ALTER COLUMN account_id SET DEFAULT nextval('finance.bank_accounts_account_id_seq'::regclass);


--
-- Name: departments department_id; Type: DEFAULT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments ALTER COLUMN department_id SET DEFAULT nextval('hr.departments_department_id_seq'::regclass);


--
-- Name: job_history history_id; Type: DEFAULT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.job_history ALTER COLUMN history_id SET DEFAULT nextval('hr.job_history_history_id_seq'::regclass);


--
-- Name: positions position_id; Type: DEFAULT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.positions ALTER COLUMN position_id SET DEFAULT nextval('hr.positions_position_id_seq'::regclass);


--
-- Name: salary_history history_id; Type: DEFAULT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.salary_history ALTER COLUMN history_id SET DEFAULT nextval('hr.salary_history_history_id_seq'::regclass);


--
-- Name: shifts shift_id; Type: DEFAULT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.shifts ALTER COLUMN shift_id SET DEFAULT nextval('hr.shifts_shift_id_seq'::regclass);


--
-- Name: teams team_id; Type: DEFAULT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams ALTER COLUMN team_id SET DEFAULT nextval('hr.teams_team_id_seq'::regclass);


--
-- Name: business_hours_config config_id; Type: DEFAULT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.business_hours_config ALTER COLUMN config_id SET DEFAULT nextval('operations.business_hours_config_config_id_seq'::regclass);


--
-- Name: feature_dependencies dependency_id; Type: DEFAULT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_dependencies ALTER COLUMN dependency_id SET DEFAULT nextval('product.feature_dependencies_dependency_id_seq'::regclass);


--
-- Name: feature_usage usage_id; Type: DEFAULT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_usage ALTER COLUMN usage_id SET DEFAULT nextval('product.feature_usage_usage_id_seq'::regclass);


--
-- Name: access_grants access_grants_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.access_grants
    ADD CONSTRAINT access_grants_pkey PRIMARY KEY (grant_id);


--
-- Name: business_units business_units_code_uk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.business_units
    ADD CONSTRAINT business_units_code_uk UNIQUE (tenant_id, organization_id, business_unit_code);


--
-- Name: business_units business_units_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.business_units
    ADD CONSTRAINT business_units_pkey PRIMARY KEY (business_unit_id);


--
-- Name: organizations organizations_code_uk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.organizations
    ADD CONSTRAINT organizations_code_uk UNIQUE (tenant_id, organization_code);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (organization_id);


--
-- Name: table_scopes table_scopes_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.table_scopes
    ADD CONSTRAINT table_scopes_pkey PRIMARY KEY (schema_name, table_name);


--
-- Name: tenant_memberships tenant_memberships_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT tenant_memberships_pkey PRIMARY KEY (membership_id);


--
-- Name: tenant_memberships tenant_memberships_user_uk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT tenant_memberships_user_uk UNIQUE (tenant_id, user_id, organization_id, business_unit_id);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (tenant_id);


--
-- Name: tenants tenants_tenant_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenants
    ADD CONSTRAINT tenants_tenant_code_key UNIQUE (tenant_code);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_uk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_username_uk UNIQUE (tenant_id, username);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (region_id);


--
-- Name: regions regions_region_code_key; Type: CONSTRAINT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.regions
    ADD CONSTRAINT regions_region_code_key UNIQUE (region_code);


--
-- Name: security_levels security_levels_level_name_key; Type: CONSTRAINT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.security_levels
    ADD CONSTRAINT security_levels_level_name_key UNIQUE (level_name);


--
-- Name: security_levels security_levels_level_value_key; Type: CONSTRAINT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.security_levels
    ADD CONSTRAINT security_levels_level_value_key UNIQUE (level_value);


--
-- Name: security_levels security_levels_pkey; Type: CONSTRAINT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.security_levels
    ADD CONSTRAINT security_levels_pkey PRIMARY KEY (level_id);


--
-- Name: builds builds_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.builds
    ADD CONSTRAINT builds_pkey PRIMARY KEY (build_id);


--
-- Name: code_repository code_repository_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.code_repository
    ADD CONSTRAINT code_repository_pkey PRIMARY KEY (repo_id);




--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (issue_id);


--
-- Name: pr_comments pr_comments_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pr_comments
    ADD CONSTRAINT pr_comments_pkey PRIMARY KEY (comment_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- Name: pull_requests pull_requests_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pull_requests
    ADD CONSTRAINT pull_requests_pkey PRIMARY KEY (pr_id);


--
-- Name: releases releases_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (release_id);


--
-- Name: tests tests_pkey; Type: CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.tests
    ADD CONSTRAINT tests_pkey PRIMARY KEY (test_id);


--
-- Name: account_transactions account_transactions_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.account_transactions
    ADD CONSTRAINT account_transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: balance_sheet balance_sheet_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.balance_sheet
    ADD CONSTRAINT balance_sheet_pkey PRIMARY KEY (record_id);


--
-- Name: bank_accounts bank_accounts_account_number_key; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.bank_accounts
    ADD CONSTRAINT bank_accounts_account_number_key UNIQUE (account_number);


--
-- Name: bank_accounts bank_accounts_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (account_id);


--
-- Name: budget budget_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.budget
    ADD CONSTRAINT budget_pkey PRIMARY KEY (budget_id);


--
-- Name: account_transactions ck_finance_account_transactions_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.account_transactions
    ADD CONSTRAINT ck_finance_account_transactions_amount_nonnegative CHECK (((amount IS NULL) OR (amount >= (0)::numeric))) NOT VALID;


--
-- Name: balance_sheet ck_finance_balance_sheet_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.balance_sheet
    ADD CONSTRAINT ck_finance_balance_sheet_amount_nonnegative CHECK (((amount IS NULL) OR (amount >= (0)::numeric))) NOT VALID;


--
-- Name: balance_sheet ck_finance_balance_sheet_balance_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.balance_sheet
    ADD CONSTRAINT ck_finance_balance_sheet_balance_nonnegative CHECK (((balance IS NULL) OR (balance >= (0)::numeric))) NOT VALID;


--
-- Name: bank_accounts ck_finance_bank_accounts_balance_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.bank_accounts
    ADD CONSTRAINT ck_finance_bank_accounts_balance_nonnegative CHECK (((balance IS NULL) OR (balance >= (0)::numeric))) NOT VALID;


--
-- Name: budget ck_finance_budget_allocated_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.budget
    ADD CONSTRAINT ck_finance_budget_allocated_amount_nonnegative CHECK (((allocated_amount IS NULL) OR (allocated_amount >= (0)::numeric))) NOT VALID;


--
-- Name: budget ck_finance_budget_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.budget
    ADD CONSTRAINT ck_finance_budget_amount_nonnegative CHECK (((amount IS NULL) OR (amount >= (0)::numeric))) NOT VALID;


--
-- Name: budget ck_finance_budget_budget_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.budget
    ADD CONSTRAINT ck_finance_budget_budget_amount_nonnegative CHECK (((budget_amount IS NULL) OR (budget_amount >= (0)::numeric))) NOT VALID;


--
-- Name: budget ck_finance_budget_cost_center_id_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.budget
    ADD CONSTRAINT ck_finance_budget_cost_center_id_nonnegative CHECK (((cost_center_id IS NULL) OR (cost_center_id >= 0))) NOT VALID;


--
-- Name: budget ck_finance_budget_increase_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.budget
    ADD CONSTRAINT ck_finance_budget_increase_amount_nonnegative CHECK (((increase_amount IS NULL) OR (increase_amount >= (0)::numeric))) NOT VALID;


--
-- Name: budget ck_finance_budget_remaining_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.budget
    ADD CONSTRAINT ck_finance_budget_remaining_amount_nonnegative CHECK (((remaining_amount IS NULL) OR (remaining_amount >= (0)::numeric))) NOT VALID;


--
-- Name: budget ck_finance_budget_spent_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.budget
    ADD CONSTRAINT ck_finance_budget_spent_amount_nonnegative CHECK (((spent_amount IS NULL) OR (spent_amount >= (0)::numeric))) NOT VALID;


--
-- Name: expenses ck_finance_expenses_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.expenses
    ADD CONSTRAINT ck_finance_expenses_amount_nonnegative CHECK (((amount IS NULL) OR (amount >= (0)::numeric))) NOT VALID;


--
-- Name: expenses ck_finance_expenses_cost_center_id_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.expenses
    ADD CONSTRAINT ck_finance_expenses_cost_center_id_nonnegative CHECK (((cost_center_id IS NULL) OR (cost_center_id >= 0))) NOT VALID;


--
-- Name: expenses ck_finance_expenses_expense_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.expenses
    ADD CONSTRAINT ck_finance_expenses_expense_amount_nonnegative CHECK (((expense_amount IS NULL) OR (expense_amount >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_finance_payroll_base_salary_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.payroll
    ADD CONSTRAINT ck_finance_payroll_base_salary_nonnegative CHECK (((base_salary IS NULL) OR (base_salary >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_finance_payroll_bonus_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.payroll
    ADD CONSTRAINT ck_finance_payroll_bonus_nonnegative CHECK (((bonus IS NULL) OR (bonus >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_finance_payroll_commission_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.payroll
    ADD CONSTRAINT ck_finance_payroll_commission_nonnegative CHECK (((commission IS NULL) OR (commission >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_finance_payroll_deductions_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.payroll
    ADD CONSTRAINT ck_finance_payroll_deductions_nonnegative CHECK (((deductions IS NULL) OR (deductions >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_finance_payroll_net_pay_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.payroll
    ADD CONSTRAINT ck_finance_payroll_net_pay_nonnegative CHECK (((net_pay IS NULL) OR (net_pay >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_finance_payroll_payroll_id_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.payroll
    ADD CONSTRAINT ck_finance_payroll_payroll_id_nonnegative CHECK (((payroll_id IS NULL) OR (payroll_id >= 0))) NOT VALID;


--
-- Name: revenue ck_finance_revenue_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.revenue
    ADD CONSTRAINT ck_finance_revenue_amount_nonnegative CHECK (((amount IS NULL) OR (amount >= (0)::numeric))) NOT VALID;


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (expense_id);




--
-- Name: bank_accounts finance_bank_accounts_status_domain_ck; Type: CHECK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE finance.bank_accounts
    ADD CONSTRAINT finance_bank_accounts_status_domain_ck CHECK (((status IS NULL) OR (lower((status)::text) = ANY (ARRAY['draft'::text, 'active'::text, 'archived'::text, 'deleted'::text, 'frozen'::text, 'reopened'::text, 'closed'::text, 'voided'::text, 'pendingreview'::text])))) NOT VALID;






--
-- Name: payroll payroll_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.payroll
    ADD CONSTRAINT payroll_pkey PRIMARY KEY (payroll_id);


--
-- Name: revenue revenue_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.revenue
    ADD CONSTRAINT revenue_pkey PRIMARY KEY (revenue_id);


--
-- Name: tax_records tax_records_pkey; Type: CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.tax_records
    ADD CONSTRAINT tax_records_pkey PRIMARY KEY (tax_id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id);


--
-- Name: benefits benefits_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.benefits
    ADD CONSTRAINT benefits_pkey PRIMARY KEY (benefit_id);


--
-- Name: attendance ck_hr_attendance_break_duration_percent; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.attendance
    ADD CONSTRAINT ck_hr_attendance_break_duration_percent CHECK (((break_duration IS NULL) OR ((break_duration >= (0)::numeric) AND (break_duration <= (100)::numeric)))) NOT VALID;


--
-- Name: benefits ck_hr_benefits_coverage_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.benefits
    ADD CONSTRAINT ck_hr_benefits_coverage_amount_nonnegative CHECK (((coverage_amount IS NULL) OR (coverage_amount >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_hr_payroll_base_salary_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.payroll
    ADD CONSTRAINT ck_hr_payroll_base_salary_nonnegative CHECK (((base_salary IS NULL) OR (base_salary >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_hr_payroll_bonus_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.payroll
    ADD CONSTRAINT ck_hr_payroll_bonus_nonnegative CHECK (((bonus IS NULL) OR (bonus >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_hr_payroll_commission_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.payroll
    ADD CONSTRAINT ck_hr_payroll_commission_nonnegative CHECK (((commission IS NULL) OR (commission >= (0)::numeric))) NOT VALID;


--
-- Name: payroll ck_hr_payroll_payroll_id_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.payroll
    ADD CONSTRAINT ck_hr_payroll_payroll_id_nonnegative CHECK (((payroll_id IS NULL) OR (payroll_id >= 0))) NOT VALID;


--
-- Name: performance ck_hr_performance_score_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.performance
    ADD CONSTRAINT ck_hr_performance_score_nonnegative CHECK (((score IS NULL) OR (score >= (0)::numeric))) NOT VALID;


--
-- Name: positions ck_hr_positions_max_salary_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.positions
    ADD CONSTRAINT ck_hr_positions_max_salary_nonnegative CHECK (((max_salary IS NULL) OR (max_salary >= (0)::numeric))) NOT VALID;


--
-- Name: positions ck_hr_positions_min_salary_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.positions
    ADD CONSTRAINT ck_hr_positions_min_salary_nonnegative CHECK (((min_salary IS NULL) OR (min_salary >= (0)::numeric))) NOT VALID;


--
-- Name: salary_history ck_hr_salary_history_base_salary_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.salary_history
    ADD CONSTRAINT ck_hr_salary_history_base_salary_nonnegative CHECK (((base_salary IS NULL) OR (base_salary >= (0)::numeric))) NOT VALID;


--
-- Name: salary_history ck_hr_salary_history_bonus_nonnegative; Type: CHECK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE hr.salary_history
    ADD CONSTRAINT ck_hr_salary_history_bonus_nonnegative CHECK (((bonus IS NULL) OR (bonus >= (0)::numeric))) NOT VALID;


--
-- Name: departments departments_department_name_key; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT departments_department_name_key UNIQUE (department_name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: employee_allowances employee_allowances_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employee_allowances
    ADD CONSTRAINT employee_allowances_pkey PRIMARY KEY (allowance_id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- Name: job_history job_history_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.job_history
    ADD CONSTRAINT job_history_pkey PRIMARY KEY (history_id);


--
-- Name: payroll payroll_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.payroll
    ADD CONSTRAINT payroll_pkey PRIMARY KEY (payroll_id);


--
-- Name: performance performance_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.performance
    ADD CONSTRAINT performance_pkey PRIMARY KEY (review_id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (position_id);


--
-- Name: positions positions_position_code_key; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.positions
    ADD CONSTRAINT positions_position_code_key UNIQUE (position_code);


--
-- Name: salary_history salary_history_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.salary_history
    ADD CONSTRAINT salary_history_pkey PRIMARY KEY (history_id);


--
-- Name: shifts shifts_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (shift_id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (team_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (log_id);


--
-- Name: backups backups_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.backups
    ADD CONSTRAINT backups_pkey PRIMARY KEY (backup_id);


--
-- Name: business_hours_config business_hours_config_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.business_hours_config
    ADD CONSTRAINT business_hours_config_pkey PRIMARY KEY (config_id);


--
-- Name: audit_logs ck_operations_audit_logs_export_size_nonnegative; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.audit_logs
    ADD CONSTRAINT ck_operations_audit_logs_export_size_nonnegative CHECK (((export_size IS NULL) OR (export_size >= 0))) NOT VALID;


--
-- Name: backups ck_operations_backups_backup_size_bytes_nonnegative; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.backups
    ADD CONSTRAINT ck_operations_backups_backup_size_bytes_nonnegative CHECK (((backup_size_bytes IS NULL) OR (backup_size_bytes >= 0))) NOT VALID;


--
-- Name: backups ck_operations_backups_compression_ratio_percent; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.backups
    ADD CONSTRAINT ck_operations_backups_compression_ratio_percent CHECK (((compression_ratio IS NULL) OR ((compression_ratio >= (0)::numeric) AND (compression_ratio <= (100)::numeric)))) NOT VALID;


--
-- Name: documents ck_operations_documents_file_size_bytes_nonnegative; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.documents
    ADD CONSTRAINT ck_operations_documents_file_size_bytes_nonnegative CHECK (((file_size_bytes IS NULL) OR (file_size_bytes >= 0))) NOT VALID;


--
-- Name: system_config ck_operations_system_config_lockout_duration_minutes_percent; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.system_config
    ADD CONSTRAINT ck_operations_system_config_lockout_duration_minutes_percent CHECK (((lockout_duration_minutes IS NULL) OR ((lockout_duration_minutes >= 0) AND (lockout_duration_minutes <= 100)))) NOT VALID;


--
-- Name: temporal_access ck_operations_temporal_access_lockout_duration_minut_e69a5e; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.temporal_access
    ADD CONSTRAINT ck_operations_temporal_access_lockout_duration_minut_e69a5e CHECK (((lockout_duration_minutes IS NULL) OR ((lockout_duration_minutes >= 0) AND (lockout_duration_minutes <= 100)))) NOT VALID;


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (document_id);


--
-- Name: entity_approval_history entity_approval_history_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_approval_history
    ADD CONSTRAINT entity_approval_history_pkey PRIMARY KEY (approval_history_id);


--
-- Name: entity_assignments entity_assignments_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_assignments
    ADD CONSTRAINT entity_assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: entity_attachments entity_attachments_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_attachments
    ADD CONSTRAINT entity_attachments_pkey PRIMARY KEY (attachment_id);


--
-- Name: entity_audit_events entity_audit_events_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_audit_events
    ADD CONSTRAINT entity_audit_events_pkey PRIMARY KEY (audit_event_id);


--
-- Name: entity_notes entity_notes_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_notes
    ADD CONSTRAINT entity_notes_pkey PRIMARY KEY (note_id);


--
-- Name: entity_status_history entity_status_history_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_status_history
    ADD CONSTRAINT entity_status_history_pkey PRIMARY KEY (status_history_id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (holiday_id);


--
-- Name: security_events operations_security_events_event_severity_domain_ck; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.security_events
    ADD CONSTRAINT operations_security_events_event_severity_domain_ck CHECK (((event_severity IS NULL) OR (lower(event_severity) = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text, 'minor'::text, 'major'::text])))) NOT VALID;


--
-- Name: security_events operations_security_events_severity_domain_ck; Type: CHECK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE operations.security_events
    ADD CONSTRAINT operations_security_events_severity_domain_ck CHECK (((severity IS NULL) OR (lower(severity) = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text, 'minor'::text, 'major'::text])))) NOT VALID;


--
-- Name: security_events security_events_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.security_events
    ADD CONSTRAINT security_events_pkey PRIMARY KEY (event_id);


--
-- Name: sensitive_access_audit sensitive_access_audit_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.sensitive_access_audit
    ADD CONSTRAINT sensitive_access_audit_pkey PRIMARY KEY (sensitive_access_id);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (config_id);


--
-- Name: temporal_access temporal_access_pkey; Type: CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.temporal_access
    ADD CONSTRAINT temporal_access_pkey PRIMARY KEY (access_id);


--
-- Name: analytics analytics_pkey; Type: CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.analytics
    ADD CONSTRAINT analytics_pkey PRIMARY KEY (analytic_id);


--
-- Name: analytics ck_product_analytics_metric_value_nonnegative; Type: CHECK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE product.analytics
    ADD CONSTRAINT ck_product_analytics_metric_value_nonnegative CHECK (((metric_value IS NULL) OR (metric_value >= (0)::numeric))) NOT VALID;


--
-- Name: features ck_product_features_business_value_nonnegative; Type: CHECK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE product.features
    ADD CONSTRAINT ck_product_features_business_value_nonnegative CHECK (((business_value IS NULL) OR (business_value >= (0)::numeric))) NOT VALID;


--
-- Name: metrics ck_product_metrics_cost_center_id_nonnegative; Type: CHECK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE product.metrics
    ADD CONSTRAINT ck_product_metrics_cost_center_id_nonnegative CHECK (((cost_center_id IS NULL) OR (cost_center_id >= 0))) NOT VALID;


--
-- Name: metrics ck_product_metrics_current_value_nonnegative; Type: CHECK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE product.metrics
    ADD CONSTRAINT ck_product_metrics_current_value_nonnegative CHECK (((current_value IS NULL) OR (current_value >= (0)::numeric))) NOT VALID;


--
-- Name: metrics ck_product_metrics_target_value_nonnegative; Type: CHECK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE product.metrics
    ADD CONSTRAINT ck_product_metrics_target_value_nonnegative CHECK (((target_value IS NULL) OR (target_value >= (0)::numeric))) NOT VALID;


--
-- Name: feature_dependencies feature_dependencies_pkey; Type: CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_dependencies
    ADD CONSTRAINT feature_dependencies_pkey PRIMARY KEY (dependency_id);


--
-- Name: feature_usage feature_usage_pkey; Type: CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_usage
    ADD CONSTRAINT feature_usage_pkey PRIMARY KEY (usage_id);


--
-- Name: features features_pkey; Type: CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (feature_id);


--
-- Name: metrics metrics_pkey; Type: CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.metrics
    ADD CONSTRAINT metrics_pkey PRIMARY KEY (metric_id);


--
-- Name: roadmap roadmap_pkey; Type: CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.roadmap
    ADD CONSTRAINT roadmap_pkey PRIMARY KEY (roadmap_id);


--
-- Name: user_feedback user_feedback_pkey; Type: CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.user_feedback
    ADD CONSTRAINT user_feedback_pkey PRIMARY KEY (feedback_id);


--
-- Name: contracts ck_sales_contracts_contract_value_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts
    ADD CONSTRAINT ck_sales_contracts_contract_value_nonnegative CHECK (((contract_value IS NULL) OR (contract_value >= (0)::numeric))) NOT VALID;


--
-- Name: contracts ck_sales_contracts_department_avg_contract_value_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts
    ADD CONSTRAINT ck_sales_contracts_department_avg_contract_value_nonnegative CHECK (((department_avg_contract_value IS NULL) OR (department_avg_contract_value >= (0)::numeric))) NOT VALID;


--
-- Name: contracts ck_sales_contracts_discount_percentage_percent; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts
    ADD CONSTRAINT ck_sales_contracts_discount_percentage_percent CHECK (((discount_percentage IS NULL) OR ((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric)))) NOT VALID;


--
-- Name: contracts ck_sales_contracts_order_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts
    ADD CONSTRAINT ck_sales_contracts_order_amount_nonnegative CHECK (((order_amount IS NULL) OR (order_amount >= (0)::numeric))) NOT VALID;


--
-- Name: customers ck_sales_customers_contract_value_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.customers
    ADD CONSTRAINT ck_sales_customers_contract_value_nonnegative CHECK (((contract_value IS NULL) OR (contract_value >= (0)::numeric))) NOT VALID;


--
-- Name: invoices ck_sales_invoices_discount_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.invoices
    ADD CONSTRAINT ck_sales_invoices_discount_amount_nonnegative CHECK (((discount_amount IS NULL) OR (discount_amount >= (0)::numeric))) NOT VALID;


--
-- Name: invoices ck_sales_invoices_net_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.invoices
    ADD CONSTRAINT ck_sales_invoices_net_amount_nonnegative CHECK (((net_amount IS NULL) OR (net_amount >= (0)::numeric))) NOT VALID;


--
-- Name: invoices ck_sales_invoices_tax_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.invoices
    ADD CONSTRAINT ck_sales_invoices_tax_amount_nonnegative CHECK (((tax_amount IS NULL) OR (tax_amount >= (0)::numeric))) NOT VALID;


--
-- Name: invoices ck_sales_invoices_total_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.invoices
    ADD CONSTRAINT ck_sales_invoices_total_amount_nonnegative CHECK (((total_amount IS NULL) OR (total_amount >= (0)::numeric))) NOT VALID;


--
-- Name: orders ck_sales_orders_contract_value_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.orders
    ADD CONSTRAINT ck_sales_orders_contract_value_nonnegative CHECK (((contract_value IS NULL) OR (contract_value >= (0)::numeric))) NOT VALID;


--
-- Name: orders ck_sales_orders_discount_percentage_percent; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.orders
    ADD CONSTRAINT ck_sales_orders_discount_percentage_percent CHECK (((discount_percentage IS NULL) OR ((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric)))) NOT VALID;


--
-- Name: orders ck_sales_orders_total_amount_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.orders
    ADD CONSTRAINT ck_sales_orders_total_amount_nonnegative CHECK (((total_amount IS NULL) OR (total_amount >= (0)::numeric))) NOT VALID;


--
-- Name: sales_pipeline ck_sales_sales_pipeline_deal_value_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.sales_pipeline
    ADD CONSTRAINT ck_sales_sales_pipeline_deal_value_nonnegative CHECK (((deal_value IS NULL) OR (deal_value >= (0)::numeric))) NOT VALID;


--
-- Name: sales_pipeline ck_sales_sales_pipeline_estimated_value_nonnegative; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.sales_pipeline
    ADD CONSTRAINT ck_sales_sales_pipeline_estimated_value_nonnegative CHECK (((estimated_value IS NULL) OR (estimated_value >= (0)::numeric))) NOT VALID;


--
-- Name: sales_pipeline ck_sales_sales_pipeline_probability_percent; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.sales_pipeline
    ADD CONSTRAINT ck_sales_sales_pipeline_probability_percent CHECK (((probability IS NULL) OR ((probability >= (0)::numeric) AND (probability <= (100)::numeric)))) NOT VALID;


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (contract_id);


--
-- Name: customer_communications customer_communications_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_communications
    ADD CONSTRAINT customer_communications_pkey PRIMARY KEY (comm_id);


--
-- Name: customer_onboarding customer_onboarding_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_onboarding
    ADD CONSTRAINT customer_onboarding_pkey PRIMARY KEY (onboarding_id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (invoice_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (region_id);


--
-- Name: contracts sales_contracts_approval_status_domain_ck; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts
    ADD CONSTRAINT sales_contracts_approval_status_domain_ck CHECK (((approval_status IS NULL) OR (lower(approval_status) = ANY (ARRAY['pending'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'reopened'::text, 'escalated'::text, 'withdrawn'::text])))) NOT VALID;


--
-- Name: contracts sales_contracts_contract_status_domain_ck; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts
    ADD CONSTRAINT sales_contracts_contract_status_domain_ck CHECK (((contract_status IS NULL) OR (lower(contract_status) = ANY (ARRAY['pending'::text, 'approved'::text, 'disputed'::text, 'active'::text, 'archived'::text])))) NOT VALID;


--
-- Name: contracts sales_contracts_payment_status_domain_ck; Type: CHECK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts
    ADD CONSTRAINT sales_contracts_payment_status_domain_ck CHECK (((payment_status IS NULL) OR (lower(payment_status) = ANY (ARRAY['pending'::text, 'paid'::text, 'unpaid'::text, 'overdue'::text, 'voided'::text])))) NOT VALID;




--
-- Name: sales_pipeline sales_pipeline_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.sales_pipeline
    ADD CONSTRAINT sales_pipeline_pkey PRIMARY KEY (pipeline_id);


--
-- Name: call_recordings call_recordings_pkey; Type: CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE ONLY support.call_recordings
    ADD CONSTRAINT call_recordings_pkey PRIMARY KEY (recording_id);


--
-- Name: call_recordings ck_support_call_recordings_call_duration_sec_percent; Type: CHECK CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE support.call_recordings
    ADD CONSTRAINT ck_support_call_recordings_call_duration_sec_percent CHECK (((call_duration_sec IS NULL) OR ((call_duration_sec >= 0) AND (call_duration_sec <= 100)))) NOT VALID;


--
-- Name: idx_auth_access_grants_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_access_grants_tenant_id ON auth.access_grants USING btree (tenant_id);


--
-- Name: idx_auth_business_units_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_business_units_tenant_id ON auth.business_units USING btree (tenant_id);


--
-- Name: idx_auth_organizations_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_organizations_tenant_id ON auth.organizations USING btree (tenant_id);


--
-- Name: idx_auth_tenant_memberships_department_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_tenant_memberships_department_id ON auth.tenant_memberships USING btree (department_id);


--
-- Name: idx_auth_tenant_memberships_employee_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_tenant_memberships_employee_id ON auth.tenant_memberships USING btree (employee_id);


--
-- Name: idx_auth_tenant_memberships_team_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_tenant_memberships_team_id ON auth.tenant_memberships USING btree (team_id);


--
-- Name: idx_auth_tenant_memberships_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_tenant_memberships_tenant_id ON auth.tenant_memberships USING btree (tenant_id);


--
-- Name: idx_auth_users_employee_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_users_employee_id ON auth.users USING btree (employee_id);


--
-- Name: idx_auth_users_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_users_tenant_id ON auth.users USING btree (tenant_id);


--
-- Name: idx_engineering_builds_project; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_builds_project ON engineering.builds USING btree (project_id);


--
-- Name: idx_engineering_builds_project_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_builds_project_id ON engineering.builds USING btree (project_id);


--
-- Name: idx_engineering_builds_status; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_builds_status ON engineering.builds USING btree (status);


--
-- Name: idx_engineering_builds_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_builds_tenant_id ON engineering.builds USING btree (tenant_id);


--
-- Name: idx_engineering_code_repository_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_code_repository_tenant_id ON engineering.code_repository USING btree (tenant_id);


--
-- Name: idx_engineering_issues_assignee; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_issues_assignee ON engineering.issues USING btree (assignee_id);


--
-- Name: idx_engineering_issues_project_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_issues_project_id ON engineering.issues USING btree (project_id);


--
-- Name: idx_engineering_issues_status; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_issues_status ON engineering.issues USING btree (status);


--
-- Name: idx_engineering_issues_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_issues_tenant_id ON engineering.issues USING btree (tenant_id);


--
-- Name: idx_engineering_pr_comments_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_pr_comments_tenant_id ON engineering.pr_comments USING btree (tenant_id);


--
-- Name: idx_engineering_projects_business_unit_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_projects_business_unit_id ON engineering.projects USING btree (business_unit_id);


--
-- Name: idx_engineering_projects_organization_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_projects_organization_id ON engineering.projects USING btree (organization_id);


--
-- Name: idx_engineering_projects_owner_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_projects_owner_id ON engineering.projects USING btree (owner_id);


--
-- Name: idx_engineering_projects_parent_project_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_projects_parent_project_id ON engineering.projects USING btree (parent_project_id);


--
-- Name: idx_engineering_projects_team; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_projects_team ON engineering.projects USING gin (team_members);


--
-- Name: idx_engineering_projects_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_projects_tenant_id ON engineering.projects USING btree (tenant_id);


--
-- Name: idx_engineering_pull_requests_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_pull_requests_tenant_id ON engineering.pull_requests USING btree (tenant_id);


--
-- Name: idx_engineering_releases_project_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_releases_project_id ON engineering.releases USING btree (project_id);


--
-- Name: idx_engineering_releases_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_releases_tenant_id ON engineering.releases USING btree (tenant_id);


--
-- Name: idx_engineering_tests_project; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_tests_project ON engineering.tests USING btree (project_id);


--
-- Name: idx_engineering_tests_status; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_tests_status ON engineering.tests USING btree (status);


--
-- Name: idx_engineering_tests_tenant_id; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_engineering_tests_tenant_id ON engineering.tests USING btree (tenant_id);


--
-- Name: idx_projects_parent; Type: INDEX; Schema: engineering; Owner: -
--

CREATE INDEX idx_projects_parent ON engineering.projects USING btree (parent_project_id);


--
-- Name: ux_engineering_issues_tenant_ticket_number; Type: INDEX; Schema: engineering; Owner: -
--

CREATE UNIQUE INDEX ux_engineering_issues_tenant_ticket_number ON engineering.issues USING btree (tenant_id, ticket_number) WHERE (ticket_number IS NOT NULL);


--
-- Name: ux_engineering_projects_tenant_project_code; Type: INDEX; Schema: engineering; Owner: -
--

CREATE UNIQUE INDEX ux_engineering_projects_tenant_project_code ON engineering.projects USING btree (tenant_id, project_code) WHERE (project_code IS NOT NULL);


--
-- Name: idx_finance_account_transactions_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_account_transactions_tenant_id ON finance.account_transactions USING btree (tenant_id);


--
-- Name: idx_finance_balance_sheet_period; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_balance_sheet_period ON finance.balance_sheet USING btree (period);


--
-- Name: idx_finance_balance_sheet_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_balance_sheet_tenant_id ON finance.balance_sheet USING btree (tenant_id);


--
-- Name: idx_finance_bank_accounts_owner_employee_id; Type: INDEX; Schema: finance; Owner: -
--



--
-- Name: idx_finance_bank_accounts_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_bank_accounts_tenant_id ON finance.bank_accounts USING btree (tenant_id);


--
-- Name: idx_finance_budget_business_unit_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_budget_business_unit_id ON finance.budget USING btree (business_unit_id);


--
-- Name: idx_finance_budget_department_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_budget_department_id ON finance.budget USING btree (department_id);


--
-- Name: idx_finance_budget_organization_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_budget_organization_id ON finance.budget USING btree (organization_id);


--
-- Name: idx_finance_budget_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_budget_tenant_id ON finance.budget USING btree (tenant_id);


--
-- Name: idx_finance_expenses_employee_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_expenses_employee_id ON finance.expenses USING btree (employee_id);


--
-- Name: idx_finance_expenses_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_expenses_tenant_id ON finance.expenses USING btree (tenant_id);


--
-- Name: idx_finance_payroll_department_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_payroll_department_id ON finance.payroll USING btree (department_id);


--
-- Name: idx_finance_payroll_employee; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_payroll_employee ON finance.payroll USING btree (employee_id);


--
-- Name: idx_finance_payroll_employee_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_payroll_employee_id ON finance.payroll USING btree (employee_id);


--
-- Name: idx_finance_payroll_period; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_payroll_period ON finance.payroll USING btree (pay_period_start, pay_period_end);


--
-- Name: idx_finance_payroll_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_payroll_tenant_id ON finance.payroll USING btree (tenant_id);


--
-- Name: idx_finance_revenue_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_revenue_tenant_id ON finance.revenue USING btree (tenant_id);


--
-- Name: idx_finance_tax_records_employee; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_tax_records_employee ON finance.tax_records USING btree (employee_id);


--
-- Name: idx_finance_tax_records_tenant_id; Type: INDEX; Schema: finance; Owner: -
--

CREATE INDEX idx_finance_tax_records_tenant_id ON finance.tax_records USING btree (tenant_id);


--
-- Name: idx_departments_parent; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_departments_parent ON hr.departments USING btree (parent_department_id);


--
-- Name: idx_hr_attendance_date; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_attendance_date ON hr.attendance USING btree (work_date);


--
-- Name: idx_hr_attendance_department_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_attendance_department_id ON hr.attendance USING btree (department_id);


--
-- Name: idx_hr_attendance_employee; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_attendance_employee ON hr.attendance USING btree (employee_id);


--
-- Name: idx_hr_attendance_employee_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_attendance_employee_id ON hr.attendance USING btree (employee_id);


--
-- Name: idx_hr_attendance_team_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_attendance_team_id ON hr.attendance USING btree (team_id);


--
-- Name: idx_hr_attendance_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_attendance_tenant_id ON hr.attendance USING btree (tenant_id);


--
-- Name: idx_hr_benefits_employee; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_benefits_employee ON hr.benefits USING btree (employee_id);


--
-- Name: idx_hr_benefits_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_benefits_tenant_id ON hr.benefits USING btree (tenant_id);


--
-- Name: idx_hr_departments_business_unit_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_departments_business_unit_id ON hr.departments USING btree (business_unit_id);


--
-- Name: idx_hr_departments_manager_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_departments_manager_id ON hr.departments USING btree (manager_id);


--
-- Name: idx_hr_departments_organization_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_departments_organization_id ON hr.departments USING btree (organization_id);


--
-- Name: idx_hr_departments_parent_department_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_departments_parent_department_id ON hr.departments USING btree (parent_department_id);


--
-- Name: idx_hr_departments_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_departments_tenant_id ON hr.departments USING btree (tenant_id);


--
-- Name: idx_hr_employee_allowances_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employee_allowances_tenant_id ON hr.employee_allowances USING btree (tenant_id);


--
-- Name: idx_hr_employees_business_unit_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_business_unit_id ON hr.employees USING btree (business_unit_id);


--
-- Name: idx_hr_employees_clearance; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_clearance ON hr.employees USING btree (security_clearance);


--
-- Name: idx_hr_employees_department_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_department_id ON hr.employees USING btree (department_id);


--
-- Name: idx_hr_employees_dept; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_dept ON hr.employees USING btree (department_id);


--
-- Name: idx_hr_employees_manager_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_manager_id ON hr.employees USING btree (manager_id);


--
-- Name: idx_hr_employees_organization_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_organization_id ON hr.employees USING btree (organization_id);


--
-- Name: idx_hr_employees_projects; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_projects ON hr.employees USING gin (project_access);


--
-- Name: idx_hr_employees_skills; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_skills ON hr.employees USING gin (skills_array);


--
-- Name: idx_hr_employees_team_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_team_id ON hr.employees USING btree (team_id);


--
-- Name: idx_hr_employees_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_employees_tenant_id ON hr.employees USING btree (tenant_id);


--
-- Name: idx_hr_job_history_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_job_history_tenant_id ON hr.job_history USING btree (tenant_id);


--
-- Name: idx_hr_payroll_dept; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_payroll_dept ON hr.payroll USING btree (department_id);


--
-- Name: idx_hr_payroll_employee; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_payroll_employee ON hr.payroll USING btree (employee_id);


--
-- Name: idx_hr_payroll_employee_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_payroll_employee_id ON hr.payroll USING btree (employee_id);


--
-- Name: idx_hr_payroll_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_payroll_tenant_id ON hr.payroll USING btree (tenant_id);


--
-- Name: idx_hr_performance_employee; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_performance_employee ON hr.performance USING btree (employee_id);


--
-- Name: idx_hr_performance_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_performance_tenant_id ON hr.performance USING btree (tenant_id);


--
-- Name: idx_hr_positions_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_positions_tenant_id ON hr.positions USING btree (tenant_id);


--
-- Name: idx_hr_salary_history_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_salary_history_tenant_id ON hr.salary_history USING btree (tenant_id);


--
-- Name: idx_hr_shifts_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_shifts_tenant_id ON hr.shifts USING btree (tenant_id);


--
-- Name: idx_hr_teams_business_unit_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_teams_business_unit_id ON hr.teams USING btree (business_unit_id);


--
-- Name: idx_hr_teams_department_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_teams_department_id ON hr.teams USING btree (department_id);


--
-- Name: idx_hr_teams_organization_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_teams_organization_id ON hr.teams USING btree (organization_id);


--
-- Name: idx_hr_teams_team_lead_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_teams_team_lead_id ON hr.teams USING btree (team_lead_id);


--
-- Name: idx_hr_teams_tenant_id; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_hr_teams_tenant_id ON hr.teams USING btree (tenant_id);


--
-- Name: idx_shifts_active; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_shifts_active ON hr.shifts USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_shifts_default; Type: INDEX; Schema: hr; Owner: -
--

CREATE INDEX idx_shifts_default ON hr.shifts USING btree (is_default) WHERE (is_default = true);


--
-- Name: ux_hr_employees_tenant_email; Type: INDEX; Schema: hr; Owner: -
--

CREATE UNIQUE INDEX ux_hr_employees_tenant_email ON hr.employees USING btree (tenant_id, lower(email)) WHERE (email IS NOT NULL);


--
-- Name: ux_hr_employees_tenant_employee_number; Type: INDEX; Schema: hr; Owner: -
--

CREATE UNIQUE INDEX ux_hr_employees_tenant_employee_number ON hr.employees USING btree (tenant_id, employee_number) WHERE (employee_number IS NOT NULL);


--
-- Name: idx_business_hours_active; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_business_hours_active ON operations.business_hours_config USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_documents_project_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_documents_project_id ON operations.documents USING btree (project_id) WHERE (project_id IS NOT NULL);


--
-- Name: idx_entity_approval_history_entity; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_entity_approval_history_entity ON operations.entity_approval_history USING btree (tenant_id, entity_schema, entity_table, entity_id);


--
-- Name: idx_entity_assignments_entity; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_entity_assignments_entity ON operations.entity_assignments USING btree (tenant_id, entity_schema, entity_table, entity_id);


--
-- Name: idx_entity_audit_events_tenant_entity; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_entity_audit_events_tenant_entity ON operations.entity_audit_events USING btree (tenant_id, entity_schema, entity_table, entity_id);


--
-- Name: idx_entity_status_history_entity; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_entity_status_history_entity ON operations.entity_status_history USING btree (tenant_id, entity_schema, entity_table, entity_id, changed_at);


--
-- Name: idx_holidays_date; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_holidays_date ON operations.holidays USING btree (holiday_date);


--
-- Name: idx_holidays_observed; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_holidays_observed ON operations.holidays USING btree (is_observed) WHERE (is_observed = true);


--
-- Name: idx_operations_audit_logs_employee_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_audit_logs_employee_id ON operations.audit_logs USING btree (employee_id);


--
-- Name: idx_operations_audit_logs_logged_at; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_audit_logs_logged_at ON operations.audit_logs USING btree (logged_at);


--
-- Name: idx_operations_audit_logs_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_audit_logs_tenant_id ON operations.audit_logs USING btree (tenant_id);


--
-- Name: idx_operations_backups_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_backups_tenant_id ON operations.backups USING btree (tenant_id);


--
-- Name: idx_operations_backups_type; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_backups_type ON operations.backups USING btree (backup_type);


--
-- Name: idx_operations_business_hours_config_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_business_hours_config_tenant_id ON operations.business_hours_config USING btree (tenant_id);


--
-- Name: idx_operations_documents_acl; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_documents_acl ON operations.documents USING gin (access_control_list);


--
-- Name: idx_operations_documents_denied; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_documents_denied ON operations.documents USING gin (denied_users);


--
-- Name: idx_operations_documents_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_documents_tenant_id ON operations.documents USING btree (tenant_id);


--
-- Name: idx_operations_holidays_date; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_holidays_date ON operations.holidays USING btree (holiday_date);


--
-- Name: idx_operations_holidays_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_holidays_tenant_id ON operations.holidays USING btree (tenant_id);


--
-- Name: idx_operations_security_events_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_security_events_tenant_id ON operations.security_events USING btree (tenant_id);


--
-- Name: idx_operations_security_events_time; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_security_events_time ON operations.security_events USING btree (event_time);


--
-- Name: idx_operations_system_config_key; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_system_config_key ON operations.system_config USING btree (config_key);


--
-- Name: idx_operations_system_config_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_system_config_tenant_id ON operations.system_config USING btree (tenant_id);


--
-- Name: idx_operations_temporal_access_tenant_id; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_temporal_access_tenant_id ON operations.temporal_access USING btree (tenant_id);


--
-- Name: idx_operations_temporal_access_user; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_operations_temporal_access_user ON operations.temporal_access USING btree (user_id);


--
-- Name: idx_sensitive_access_audit_tenant_target; Type: INDEX; Schema: operations; Owner: -
--

CREATE INDEX idx_sensitive_access_audit_tenant_target ON operations.sensitive_access_audit USING btree (tenant_id, target_schema, target_table, target_id);


--
-- Name: idx_product_analytics_metric; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_analytics_metric ON product.analytics USING btree (metric_name);


--
-- Name: idx_product_analytics_tenant_id; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_analytics_tenant_id ON product.analytics USING btree (tenant_id);


--
-- Name: idx_product_feature_dependencies_tenant_id; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_feature_dependencies_tenant_id ON product.feature_dependencies USING btree (tenant_id);


--
-- Name: idx_product_feature_usage_tenant_id; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_feature_usage_tenant_id ON product.feature_usage USING btree (tenant_id);


--
-- Name: idx_product_features_status; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_features_status ON product.features USING btree (status);


--
-- Name: idx_product_features_tenant_id; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_features_tenant_id ON product.features USING btree (tenant_id);


--
-- Name: idx_product_metrics_name; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_metrics_name ON product.metrics USING btree (metric_name);


--
-- Name: idx_product_metrics_tenant_id; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_metrics_tenant_id ON product.metrics USING btree (tenant_id);


--
-- Name: idx_product_roadmap_tenant_id; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_roadmap_tenant_id ON product.roadmap USING btree (tenant_id);


--
-- Name: idx_product_user_feedback_tenant_id; Type: INDEX; Schema: product; Owner: -
--

CREATE INDEX idx_product_user_feedback_tenant_id ON product.user_feedback USING btree (tenant_id);


--
-- Name: idx_sales_contracts_business_unit_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_contracts_business_unit_id ON sales.contracts USING btree (business_unit_id);


--
-- Name: idx_sales_contracts_customer_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_contracts_customer_id ON sales.contracts USING btree (customer_id);


--
-- Name: idx_sales_contracts_organization_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_contracts_organization_id ON sales.contracts USING btree (organization_id);


--
-- Name: idx_sales_contracts_sales_rep_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_contracts_sales_rep_id ON sales.contracts USING btree (sales_rep_id);


--
-- Name: idx_sales_contracts_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_contracts_tenant_id ON sales.contracts USING btree (tenant_id);


--
-- Name: idx_sales_customer_communications_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_customer_communications_tenant_id ON sales.customer_communications USING btree (tenant_id);


--
-- Name: idx_sales_customer_onboarding_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_customer_onboarding_tenant_id ON sales.customer_onboarding USING btree (tenant_id);


--
-- Name: idx_sales_customers_account_manager_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_customers_account_manager_id ON sales.customers USING btree (account_manager_id);


--
-- Name: idx_sales_customers_business_unit_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_customers_business_unit_id ON sales.customers USING btree (business_unit_id);


--
-- Name: idx_sales_customers_organization_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_customers_organization_id ON sales.customers USING btree (organization_id);


--
-- Name: idx_sales_customers_parent_customer_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_customers_parent_customer_id ON sales.customers USING btree (parent_customer_id);


--
-- Name: idx_sales_customers_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_customers_tenant_id ON sales.customers USING btree (tenant_id);


--
-- Name: idx_sales_invoices_contract_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_invoices_contract_id ON sales.invoices USING btree (contract_id);


--
-- Name: idx_sales_invoices_customer; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_invoices_customer ON sales.invoices USING btree (customer_id);


--
-- Name: idx_sales_invoices_customer_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_invoices_customer_id ON sales.invoices USING btree (customer_id);


--
-- Name: idx_sales_invoices_status; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_invoices_status ON sales.invoices USING btree (status);


--
-- Name: idx_sales_invoices_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_invoices_tenant_id ON sales.invoices USING btree (tenant_id);


--
-- Name: idx_sales_orders_customer_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_orders_customer_id ON sales.orders USING btree (customer_id);


--
-- Name: idx_sales_orders_sales_rep_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_orders_sales_rep_id ON sales.orders USING btree (sales_rep_id);


--
-- Name: idx_sales_orders_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_orders_tenant_id ON sales.orders USING btree (tenant_id);


--
-- Name: idx_sales_pipeline_customer; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_pipeline_customer ON sales.sales_pipeline USING btree (customer_id);


--
-- Name: idx_sales_pipeline_stage; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_pipeline_stage ON sales.sales_pipeline USING btree (stage);


--
-- Name: idx_sales_regions_parent_region_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_regions_parent_region_id ON sales.regions USING btree (parent_region_id);


--
-- Name: idx_sales_regions_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_regions_tenant_id ON sales.regions USING btree (tenant_id);


--
-- Name: idx_sales_sales_pipeline_account_manager_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_sales_pipeline_account_manager_id ON sales.sales_pipeline USING btree (account_manager_id);


--
-- Name: idx_sales_sales_pipeline_customer_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_sales_pipeline_customer_id ON sales.sales_pipeline USING btree (customer_id);


--
-- Name: idx_sales_sales_pipeline_tenant_id; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_sales_sales_pipeline_tenant_id ON sales.sales_pipeline USING btree (tenant_id);


--
-- Name: ux_sales_contracts_tenant_contract_number; Type: INDEX; Schema: sales; Owner: -
--

CREATE UNIQUE INDEX ux_sales_contracts_tenant_contract_number ON sales.contracts USING btree (tenant_id, contract_number) WHERE (contract_number IS NOT NULL);


--
-- Name: ux_sales_customers_tenant_customer_code; Type: INDEX; Schema: sales; Owner: -
--

CREATE UNIQUE INDEX ux_sales_customers_tenant_customer_code ON sales.customers USING btree (tenant_id, customer_code) WHERE (customer_code IS NOT NULL);


--
-- Name: ux_sales_invoices_tenant_invoice_number; Type: INDEX; Schema: sales; Owner: -
--

CREATE UNIQUE INDEX ux_sales_invoices_tenant_invoice_number ON sales.invoices USING btree (tenant_id, invoice_number) WHERE (invoice_number IS NOT NULL);


--
-- Name: idx_support_call_recordings_agent_id; Type: INDEX; Schema: support; Owner: -
--

CREATE INDEX idx_support_call_recordings_agent_id ON support.call_recordings USING btree (agent_id);


--
-- Name: idx_support_call_recordings_team_id; Type: INDEX; Schema: support; Owner: -
--

CREATE INDEX idx_support_call_recordings_team_id ON support.call_recordings USING btree (team_id);


--
-- Name: idx_support_call_recordings_tenant_id; Type: INDEX; Schema: support; Owner: -
--

CREATE INDEX idx_support_call_recordings_tenant_id ON support.call_recordings USING btree (tenant_id);


--
-- Name: access_grants trg_set_row_metadata; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON auth.access_grants FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: business_units trg_set_row_metadata; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON auth.business_units FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: organizations trg_set_row_metadata; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON auth.organizations FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: table_scopes trg_set_row_metadata; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON auth.table_scopes FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: tenant_memberships trg_set_row_metadata; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON auth.tenant_memberships FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: tenants trg_set_row_metadata; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON auth.tenants FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: users trg_set_row_metadata; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: builds trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.builds FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: code_repository trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.code_repository FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: issues trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.issues FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: pr_comments trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.pr_comments FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: projects trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.projects FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: pull_requests trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.pull_requests FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: releases trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.releases FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: tests trg_set_row_metadata; Type: TRIGGER; Schema: engineering; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON engineering.tests FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: bank_accounts trg_capture_sensitive_row_change; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_capture_sensitive_row_change AFTER INSERT OR DELETE OR UPDATE ON finance.bank_accounts FOR EACH ROW EXECUTE FUNCTION operations.capture_sensitive_row_change();


--
-- Name: payroll trg_capture_sensitive_row_change; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_capture_sensitive_row_change AFTER INSERT OR DELETE OR UPDATE ON finance.payroll FOR EACH ROW EXECUTE FUNCTION operations.capture_sensitive_row_change();


--
-- Name: account_transactions trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.account_transactions FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: balance_sheet trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.balance_sheet FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: bank_accounts trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.bank_accounts FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: budget trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.budget FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: expenses trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.expenses FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: payroll trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.payroll FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: revenue trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.revenue FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: tax_records trg_set_row_metadata; Type: TRIGGER; Schema: finance; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON finance.tax_records FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: employees trg_capture_sensitive_row_change; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_capture_sensitive_row_change AFTER INSERT OR DELETE OR UPDATE ON hr.employees FOR EACH ROW EXECUTE FUNCTION operations.capture_sensitive_row_change();


--
-- Name: payroll trg_capture_sensitive_row_change; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_capture_sensitive_row_change AFTER INSERT OR DELETE OR UPDATE ON hr.payroll FOR EACH ROW EXECUTE FUNCTION operations.capture_sensitive_row_change();


--
-- Name: attendance trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.attendance FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: benefits trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.benefits FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: departments trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.departments FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: employee_allowances trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.employee_allowances FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: employees trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.employees FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: job_history trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.job_history FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: payroll trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.payroll FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: performance trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.performance FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: positions trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.positions FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: salary_history trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.salary_history FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: shifts trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.shifts FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: teams trg_set_row_metadata; Type: TRIGGER; Schema: hr; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON hr.teams FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: security_events trg_capture_sensitive_row_change; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_capture_sensitive_row_change AFTER INSERT OR DELETE OR UPDATE ON operations.security_events FOR EACH ROW EXECUTE FUNCTION operations.capture_sensitive_row_change();


--
-- Name: audit_logs trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.audit_logs FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: backups trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.backups FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: business_hours_config trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.business_hours_config FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: documents trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.documents FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: holidays trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.holidays FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: security_events trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.security_events FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: system_config trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.system_config FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: temporal_access trg_set_row_metadata; Type: TRIGGER; Schema: operations; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON operations.temporal_access FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: analytics trg_set_row_metadata; Type: TRIGGER; Schema: product; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON product.analytics FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: feature_dependencies trg_set_row_metadata; Type: TRIGGER; Schema: product; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON product.feature_dependencies FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: feature_usage trg_set_row_metadata; Type: TRIGGER; Schema: product; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON product.feature_usage FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: features trg_set_row_metadata; Type: TRIGGER; Schema: product; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON product.features FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: metrics trg_set_row_metadata; Type: TRIGGER; Schema: product; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON product.metrics FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: roadmap trg_set_row_metadata; Type: TRIGGER; Schema: product; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON product.roadmap FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: user_feedback trg_set_row_metadata; Type: TRIGGER; Schema: product; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON product.user_feedback FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: contracts trg_capture_sensitive_row_change; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_capture_sensitive_row_change AFTER INSERT OR DELETE OR UPDATE ON sales.contracts FOR EACH ROW EXECUTE FUNCTION operations.capture_sensitive_row_change();


--
-- Name: contracts trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.contracts FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: customer_communications trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.customer_communications FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: customer_onboarding trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.customer_onboarding FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: customers trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.customers FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: invoices trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.invoices FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: orders trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.orders FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: regions trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.regions FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: sales_pipeline trg_set_row_metadata; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON sales.sales_pipeline FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: call_recordings trg_set_row_metadata; Type: TRIGGER; Schema: support; Owner: -
--

CREATE TRIGGER trg_set_row_metadata BEFORE UPDATE ON support.call_recordings FOR EACH ROW EXECUTE FUNCTION auth.set_row_metadata();


--
-- Name: access_grants auth_access_grants_tenant_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.access_grants
    ADD CONSTRAINT auth_access_grants_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;

--
-- Name: access_grants fk_auth_access_grants_user_id_auth_users; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.access_grants
    ADD CONSTRAINT fk_auth_access_grants_user_id_auth_users FOREIGN KEY (user_id) REFERENCES auth.users(user_id);


--
-- Name: business_units auth_business_units_tenant_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.business_units
    ADD CONSTRAINT auth_business_units_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: organizations auth_organizations_tenant_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.organizations
    ADD CONSTRAINT auth_organizations_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: tenant_memberships auth_tenant_memberships_department_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT auth_tenant_memberships_department_id_fk FOREIGN KEY (department_id) REFERENCES hr.departments(department_id) NOT VALID;


--
-- Name: tenant_memberships auth_tenant_memberships_employee_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT auth_tenant_memberships_employee_id_fk FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: tenant_memberships auth_tenant_memberships_team_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT auth_tenant_memberships_team_id_fk FOREIGN KEY (team_id) REFERENCES hr.teams(team_id) NOT VALID;


--
-- Name: tenant_memberships auth_tenant_memberships_tenant_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT auth_tenant_memberships_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: users auth_users_employee_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT auth_users_employee_id_fk FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: users auth_users_tenant_id_fk; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT auth_users_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: business_units business_units_organization_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.business_units
    ADD CONSTRAINT business_units_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id);


--
-- Name: business_units business_units_parent_business_unit_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.business_units
    ADD CONSTRAINT business_units_parent_business_unit_id_fkey FOREIGN KEY (parent_business_unit_id) REFERENCES auth.business_units(business_unit_id);


--
-- Name: business_units business_units_tenant_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.business_units
    ADD CONSTRAINT business_units_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: organizations organizations_parent_organization_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.organizations
    ADD CONSTRAINT organizations_parent_organization_id_fkey FOREIGN KEY (parent_organization_id) REFERENCES auth.organizations(organization_id);


--
-- Name: organizations organizations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.organizations
    ADD CONSTRAINT organizations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: tenant_memberships tenant_memberships_business_unit_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT tenant_memberships_business_unit_id_fkey FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id);


--
-- Name: tenant_memberships tenant_memberships_organization_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT tenant_memberships_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id);


--
-- Name: tenant_memberships tenant_memberships_tenant_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT tenant_memberships_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: tenant_memberships tenant_memberships_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.tenant_memberships
    ADD CONSTRAINT tenant_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(user_id);


--
-- Name: users users_tenant_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: regions fk_parent_region; Type: FK CONSTRAINT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.regions
    ADD CONSTRAINT fk_parent_region FOREIGN KEY (parent_region_id) REFERENCES common.regions(region_id);


--
-- Name: regions fk_region_manager; Type: FK CONSTRAINT; Schema: common; Owner: -
--

ALTER TABLE ONLY common.regions
    ADD CONSTRAINT fk_region_manager FOREIGN KEY (manager_id) REFERENCES hr.employees(employee_id);


--
-- Name: builds engineering_builds_project_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.builds
    ADD CONSTRAINT engineering_builds_project_id_fk FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id) NOT VALID;


--
-- Name: builds engineering_builds_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.builds
    ADD CONSTRAINT engineering_builds_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: code_repository engineering_code_repository_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.code_repository
    ADD CONSTRAINT engineering_code_repository_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: issues engineering_issues_project_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.issues
    ADD CONSTRAINT engineering_issues_project_id_fk FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id) NOT VALID;


--
-- Name: issues engineering_issues_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.issues
    ADD CONSTRAINT engineering_issues_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: pr_comments engineering_pr_comments_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pr_comments
    ADD CONSTRAINT engineering_pr_comments_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: projects engineering_projects_business_unit_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT engineering_projects_business_unit_id_fk FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id) NOT VALID;


--
-- Name: projects engineering_projects_organization_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT engineering_projects_organization_id_fk FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id) NOT VALID;


--
-- Name: projects engineering_projects_owner_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT engineering_projects_owner_id_fk FOREIGN KEY (owner_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: projects engineering_projects_parent_project_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT engineering_projects_parent_project_id_fk FOREIGN KEY (parent_project_id) REFERENCES engineering.projects(project_id) NOT VALID;


--
-- Name: projects engineering_projects_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT engineering_projects_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: pull_requests engineering_pull_requests_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pull_requests
    ADD CONSTRAINT engineering_pull_requests_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: releases engineering_releases_project_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.releases
    ADD CONSTRAINT engineering_releases_project_id_fk FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id) NOT VALID;


--
-- Name: releases engineering_releases_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.releases
    ADD CONSTRAINT engineering_releases_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: tests engineering_tests_tenant_id_fk; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.tests
    ADD CONSTRAINT engineering_tests_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: builds fk_engineering_builds_project_id_engineering_projects; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.builds
    ADD CONSTRAINT fk_engineering_builds_project_id_engineering_projects FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id);


--
-- Name: code_repository fk_engineering_code_repository_owner_id_hr_employees; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.code_repository
    ADD CONSTRAINT fk_engineering_code_repository_owner_id_hr_employees FOREIGN KEY (owner_id) REFERENCES hr.employees(employee_id);


--
-- Name: code_repository fk_engineering_code_repository_project_id_engineering_projects; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.code_repository
    ADD CONSTRAINT fk_engineering_code_repository_project_id_engineering_projects FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id);


--
-- Name: issues fk_engineering_issues_assignee_id_hr_employees; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.issues
    ADD CONSTRAINT fk_engineering_issues_assignee_id_hr_employees FOREIGN KEY (assignee_id) REFERENCES hr.employees(employee_id);


--
-- Name: issues fk_engineering_issues_project_id_engineering_projects; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.issues
    ADD CONSTRAINT fk_engineering_issues_project_id_engineering_projects FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id);


--
-- Name: issues fk_engineering_issues_reporter_id_hr_employees; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.issues
    ADD CONSTRAINT fk_engineering_issues_reporter_id_hr_employees FOREIGN KEY (reporter_id) REFERENCES hr.employees(employee_id);


--
-- Name: projects fk_engineering_projects_department_id_hr_departments; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT fk_engineering_projects_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: projects fk_engineering_projects_owner_id_hr_employees; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT fk_engineering_projects_owner_id_hr_employees FOREIGN KEY (owner_id) REFERENCES hr.employees(employee_id);


--
-- Name: tests fk_engineering_tests_project_id_engineering_projects; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.tests
    ADD CONSTRAINT fk_engineering_tests_project_id_engineering_projects FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id);


--
-- Name: pr_comments pr_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pr_comments
    ADD CONSTRAINT pr_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES hr.employees(employee_id);


--
-- Name: pr_comments pr_comments_pr_id_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pr_comments
    ADD CONSTRAINT pr_comments_pr_id_fkey FOREIGN KEY (pr_id) REFERENCES engineering.pull_requests(pr_id);


--
-- Name: projects projects_parent_project_id_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.projects
    ADD CONSTRAINT projects_parent_project_id_fkey FOREIGN KEY (parent_project_id) REFERENCES engineering.projects(project_id);


--
-- Name: pull_requests pull_requests_author_id_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pull_requests
    ADD CONSTRAINT pull_requests_author_id_fkey FOREIGN KEY (author_id) REFERENCES hr.employees(employee_id);


--
-- Name: pull_requests pull_requests_merged_by_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pull_requests
    ADD CONSTRAINT pull_requests_merged_by_fkey FOREIGN KEY (merged_by) REFERENCES hr.employees(employee_id);


--
-- Name: pull_requests pull_requests_repo_id_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.pull_requests
    ADD CONSTRAINT pull_requests_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES engineering.code_repository(repo_id);


--
-- Name: releases releases_project_id_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.releases
    ADD CONSTRAINT releases_project_id_fkey FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id);


--
-- Name: tests tests_release_id_fkey; Type: FK CONSTRAINT; Schema: engineering; Owner: -
--

ALTER TABLE ONLY engineering.tests
    ADD CONSTRAINT tests_release_id_fkey FOREIGN KEY (release_id) REFERENCES engineering.releases(release_id);


--
-- Name: account_transactions account_transactions_account_id_fkey; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.account_transactions
    ADD CONSTRAINT account_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES finance.bank_accounts(account_id);


--
-- Name: bank_accounts bank_accounts_owner_employee_id_fkey; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.bank_accounts
    ADD CONSTRAINT bank_accounts_owner_employee_id_fkey FOREIGN KEY (owner_employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: expenses expenses_dept_id_fkey; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.expenses
    ADD CONSTRAINT expenses_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES hr.departments(department_id);


--
-- Name: account_transactions finance_account_transactions_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.account_transactions
    ADD CONSTRAINT finance_account_transactions_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: balance_sheet finance_balance_sheet_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.balance_sheet
    ADD CONSTRAINT finance_balance_sheet_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: bank_accounts finance_bank_accounts_owner_employee_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.bank_accounts
    ADD CONSTRAINT finance_bank_accounts_owner_employee_id_fk FOREIGN KEY (owner_employee_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: bank_accounts finance_bank_accounts_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.bank_accounts
    ADD CONSTRAINT finance_bank_accounts_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: budget finance_budget_business_unit_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.budget
    ADD CONSTRAINT finance_budget_business_unit_id_fk FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id) NOT VALID;


--
-- Name: budget finance_budget_department_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.budget
    ADD CONSTRAINT finance_budget_department_id_fk FOREIGN KEY (department_id) REFERENCES hr.departments(department_id) NOT VALID;


--
-- Name: budget finance_budget_organization_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.budget
    ADD CONSTRAINT finance_budget_organization_id_fk FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id) NOT VALID;


--
-- Name: budget finance_budget_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.budget
    ADD CONSTRAINT finance_budget_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: expenses finance_expenses_employee_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.expenses
    ADD CONSTRAINT finance_expenses_employee_id_fk FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: expenses finance_expenses_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.expenses
    ADD CONSTRAINT finance_expenses_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: payroll finance_payroll_department_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.payroll
    ADD CONSTRAINT finance_payroll_department_id_fk FOREIGN KEY (department_id) REFERENCES hr.departments(department_id) NOT VALID;


--
-- Name: payroll finance_payroll_employee_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.payroll
    ADD CONSTRAINT finance_payroll_employee_id_fk FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: payroll finance_payroll_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.payroll
    ADD CONSTRAINT finance_payroll_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: revenue finance_revenue_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.revenue
    ADD CONSTRAINT finance_revenue_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: tax_records finance_tax_records_tenant_id_fk; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.tax_records
    ADD CONSTRAINT finance_tax_records_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: budget fk_finance_budget_department_id_hr_departments; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.budget
    ADD CONSTRAINT fk_finance_budget_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: expenses fk_finance_expenses_department_id_hr_departments; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.expenses
    ADD CONSTRAINT fk_finance_expenses_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: expenses fk_finance_expenses_employee_id_hr_employees; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.expenses
    ADD CONSTRAINT fk_finance_expenses_employee_id_hr_employees FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: payroll fk_finance_payroll_department_id_hr_departments; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.payroll
    ADD CONSTRAINT fk_finance_payroll_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: payroll fk_finance_payroll_employee_id_hr_employees; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.payroll
    ADD CONSTRAINT fk_finance_payroll_employee_id_hr_employees FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: revenue fk_finance_revenue_contract_id_sales_contracts; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.revenue
    ADD CONSTRAINT fk_finance_revenue_contract_id_sales_contracts FOREIGN KEY (contract_id) REFERENCES sales.contracts(contract_id);


--
-- Name: revenue fk_finance_revenue_customer_id_sales_customers; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.revenue
    ADD CONSTRAINT fk_finance_revenue_customer_id_sales_customers FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: revenue fk_finance_revenue_department_id_hr_departments; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.revenue
    ADD CONSTRAINT fk_finance_revenue_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: tax_records fk_finance_tax_records_employee_id_hr_employees; Type: FK CONSTRAINT; Schema: finance; Owner: -
--

ALTER TABLE ONLY finance.tax_records
    ADD CONSTRAINT fk_finance_tax_records_employee_id_hr_employees FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: employee_allowances employee_allowances_approved_by_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employee_allowances
    ADD CONSTRAINT employee_allowances_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES hr.employees(employee_id);


--
-- Name: employee_allowances employee_allowances_employee_id_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employee_allowances
    ADD CONSTRAINT employee_allowances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: attendance fk_attendance_shift_id; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.attendance
    ADD CONSTRAINT fk_attendance_shift_id FOREIGN KEY (shift_id) REFERENCES hr.shifts(shift_id);


--
-- Name: departments fk_department_parent; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT fk_department_parent FOREIGN KEY (parent_dept_id) REFERENCES hr.departments(department_id);


--
-- Name: departments fk_department_parent_dept_id; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT fk_department_parent_dept_id FOREIGN KEY (parent_department_id) REFERENCES hr.departments(department_id);


--
-- Name: attendance fk_hr_attendance_employee_id_hr_employees; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.attendance
    ADD CONSTRAINT fk_hr_attendance_employee_id_hr_employees FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: benefits fk_hr_benefits_employee_id_hr_employees; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.benefits
    ADD CONSTRAINT fk_hr_benefits_employee_id_hr_employees FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: employees fk_hr_employees_department_id_hr_departments; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT fk_hr_employees_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: employees fk_hr_employees_manager_id_hr_employees; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT fk_hr_employees_manager_id_hr_employees FOREIGN KEY (manager_id) REFERENCES hr.employees(employee_id);


--
-- Name: performance fk_hr_performance_employee_id_hr_employees; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.performance
    ADD CONSTRAINT fk_hr_performance_employee_id_hr_employees FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: performance fk_hr_performance_reviewer_id_hr_employees; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.performance
    ADD CONSTRAINT fk_hr_performance_reviewer_id_hr_employees FOREIGN KEY (reviewer_id) REFERENCES hr.employees(employee_id);


--
-- Name: teams fk_team_lead; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT fk_team_lead FOREIGN KEY (team_lead_id) REFERENCES hr.employees(employee_id);


--
-- Name: attendance hr_attendance_department_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.attendance
    ADD CONSTRAINT hr_attendance_department_id_fk FOREIGN KEY (department_id) REFERENCES hr.departments(department_id) NOT VALID;


--
-- Name: attendance hr_attendance_employee_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.attendance
    ADD CONSTRAINT hr_attendance_employee_id_fk FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: attendance hr_attendance_team_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.attendance
    ADD CONSTRAINT hr_attendance_team_id_fk FOREIGN KEY (team_id) REFERENCES hr.teams(team_id) NOT VALID;


--
-- Name: attendance hr_attendance_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.attendance
    ADD CONSTRAINT hr_attendance_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: benefits hr_benefits_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.benefits
    ADD CONSTRAINT hr_benefits_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: departments hr_departments_business_unit_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT hr_departments_business_unit_id_fk FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id) NOT VALID;


--
-- Name: departments hr_departments_manager_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT hr_departments_manager_id_fk FOREIGN KEY (manager_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: departments hr_departments_organization_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT hr_departments_organization_id_fk FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id) NOT VALID;


--
-- Name: departments hr_departments_parent_department_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT hr_departments_parent_department_id_fk FOREIGN KEY (parent_department_id) REFERENCES hr.departments(department_id) NOT VALID;


--
-- Name: departments hr_departments_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.departments
    ADD CONSTRAINT hr_departments_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: employee_allowances hr_employee_allowances_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employee_allowances
    ADD CONSTRAINT hr_employee_allowances_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: employees hr_employees_business_unit_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT hr_employees_business_unit_id_fk FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id) NOT VALID;


--
-- Name: employees hr_employees_department_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT hr_employees_department_id_fk FOREIGN KEY (department_id) REFERENCES hr.departments(department_id) NOT VALID;


--
-- Name: employees hr_employees_manager_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT hr_employees_manager_id_fk FOREIGN KEY (manager_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: employees hr_employees_organization_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT hr_employees_organization_id_fk FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id) NOT VALID;


--
-- Name: employees hr_employees_team_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT hr_employees_team_id_fk FOREIGN KEY (team_id) REFERENCES hr.teams(team_id) NOT VALID;


--
-- Name: employees hr_employees_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.employees
    ADD CONSTRAINT hr_employees_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: job_history hr_job_history_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.job_history
    ADD CONSTRAINT hr_job_history_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: payroll hr_payroll_employee_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.payroll
    ADD CONSTRAINT hr_payroll_employee_id_fk FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: payroll hr_payroll_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.payroll
    ADD CONSTRAINT hr_payroll_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: performance hr_performance_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.performance
    ADD CONSTRAINT hr_performance_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: positions hr_positions_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.positions
    ADD CONSTRAINT hr_positions_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: salary_history hr_salary_history_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.salary_history
    ADD CONSTRAINT hr_salary_history_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: shifts hr_shifts_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.shifts
    ADD CONSTRAINT hr_shifts_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: teams hr_teams_business_unit_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT hr_teams_business_unit_id_fk FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id) NOT VALID;


--
-- Name: teams hr_teams_department_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT hr_teams_department_id_fk FOREIGN KEY (department_id) REFERENCES hr.departments(department_id) NOT VALID;


--
-- Name: teams hr_teams_organization_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT hr_teams_organization_id_fk FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id) NOT VALID;


--
-- Name: teams hr_teams_team_lead_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT hr_teams_team_lead_id_fk FOREIGN KEY (team_lead_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: teams hr_teams_tenant_id_fk; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT hr_teams_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: job_history job_history_employee_id_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.job_history
    ADD CONSTRAINT job_history_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: performance performance_dept_id_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.performance
    ADD CONSTRAINT performance_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES hr.departments(department_id);


--
-- Name: positions positions_department_id_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.positions
    ADD CONSTRAINT positions_department_id_fkey FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: salary_history salary_history_approved_by_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.salary_history
    ADD CONSTRAINT salary_history_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES hr.employees(employee_id);


--
-- Name: salary_history salary_history_employee_id_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.salary_history
    ADD CONSTRAINT salary_history_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: teams teams_department_id_fkey; Type: FK CONSTRAINT; Schema: hr; Owner: -
--

ALTER TABLE ONLY hr.teams
    ADD CONSTRAINT teams_department_id_fkey FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: business_hours_config business_hours_config_default_shift_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.business_hours_config
    ADD CONSTRAINT business_hours_config_default_shift_id_fkey FOREIGN KEY (default_shift_id) REFERENCES hr.shifts(shift_id);


--
-- Name: entity_approval_history entity_approval_history_tenant_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_approval_history
    ADD CONSTRAINT entity_approval_history_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: entity_assignments entity_assignments_tenant_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_assignments
    ADD CONSTRAINT entity_assignments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: entity_attachments entity_attachments_tenant_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_attachments
    ADD CONSTRAINT entity_attachments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: entity_audit_events entity_audit_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_audit_events
    ADD CONSTRAINT entity_audit_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: entity_notes entity_notes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_notes
    ADD CONSTRAINT entity_notes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: entity_status_history entity_status_history_tenant_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.entity_status_history
    ADD CONSTRAINT entity_status_history_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: documents fk_documents_project; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.documents
    ADD CONSTRAINT fk_documents_project FOREIGN KEY (project_id) REFERENCES engineering.projects(project_id) ON DELETE SET NULL;


--
-- Name: audit_logs fk_operations_audit_logs_employee_id_hr_employees; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.audit_logs
    ADD CONSTRAINT fk_operations_audit_logs_employee_id_hr_employees FOREIGN KEY (employee_id) REFERENCES hr.employees(employee_id);


--
-- Name: documents fk_operations_documents_author_id_hr_employees; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.documents
    ADD CONSTRAINT fk_operations_documents_author_id_hr_employees FOREIGN KEY (author_id) REFERENCES hr.employees(employee_id);


--
-- Name: documents fk_operations_documents_department_id_hr_departments; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.documents
    ADD CONSTRAINT fk_operations_documents_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: temporal_access fk_operations_temporal_access_granted_by_hr_employees; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.temporal_access
    ADD CONSTRAINT fk_operations_temporal_access_granted_by_hr_employees FOREIGN KEY (granted_by) REFERENCES hr.employees(employee_id);


--
-- Name: temporal_access fk_operations_temporal_access_user_id_auth_users; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.temporal_access
    ADD CONSTRAINT fk_operations_temporal_access_user_id_auth_users FOREIGN KEY (user_id) REFERENCES auth.users(user_id);


--
-- Name: audit_logs operations_audit_logs_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.audit_logs
    ADD CONSTRAINT operations_audit_logs_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: backups operations_backups_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.backups
    ADD CONSTRAINT operations_backups_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: business_hours_config operations_business_hours_config_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.business_hours_config
    ADD CONSTRAINT operations_business_hours_config_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: documents operations_documents_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.documents
    ADD CONSTRAINT operations_documents_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: holidays operations_holidays_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.holidays
    ADD CONSTRAINT operations_holidays_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: security_events fk_operations_security_events_user_id_auth_users; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.security_events
    ADD CONSTRAINT fk_operations_security_events_user_id_auth_users FOREIGN KEY (user_id) REFERENCES auth.users(user_id);


-- Name: security_events operations_security_events_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.security_events
    ADD CONSTRAINT operations_security_events_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: system_config operations_system_config_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.system_config
    ADD CONSTRAINT operations_system_config_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: temporal_access operations_temporal_access_tenant_id_fk; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.temporal_access
    ADD CONSTRAINT operations_temporal_access_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: sensitive_access_audit sensitive_access_audit_tenant_id_fkey; Type: FK CONSTRAINT; Schema: operations; Owner: -
--

ALTER TABLE ONLY operations.sensitive_access_audit
    ADD CONSTRAINT sensitive_access_audit_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id);


--
-- Name: feature_dependencies feature_dependencies_depends_on_feature_id_fkey; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_dependencies
    ADD CONSTRAINT feature_dependencies_depends_on_feature_id_fkey FOREIGN KEY (depends_on_feature_id) REFERENCES product.features(feature_id);


--
-- Name: feature_dependencies feature_dependencies_feature_id_fkey; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_dependencies
    ADD CONSTRAINT feature_dependencies_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES product.features(feature_id);


--
-- Name: feature_usage feature_usage_feature_id_fkey; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_usage
    ADD CONSTRAINT feature_usage_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES product.features(feature_id);


--
-- Name: features fk_product_features_assigned_to_hr_employees; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.features
    ADD CONSTRAINT fk_product_features_assigned_to_hr_employees FOREIGN KEY (assigned_to) REFERENCES hr.employees(employee_id);


--
-- Name: features fk_product_features_product_id_engineering_projects; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.features
    ADD CONSTRAINT fk_product_features_product_id_engineering_projects FOREIGN KEY (product_id) REFERENCES engineering.projects(project_id);


--
-- Name: user_feedback fk_product_user_feedback_department_id_hr_departments; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.user_feedback
    ADD CONSTRAINT fk_product_user_feedback_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: user_feedback fk_product_user_feedback_product_id_engineering_projects; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.user_feedback
    ADD CONSTRAINT fk_product_user_feedback_product_id_engineering_projects FOREIGN KEY (product_id) REFERENCES engineering.projects(project_id);


--
-- Name: analytics product_analytics_tenant_id_fk; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.analytics
    ADD CONSTRAINT product_analytics_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: feature_dependencies product_feature_dependencies_tenant_id_fk; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_dependencies
    ADD CONSTRAINT product_feature_dependencies_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: feature_usage product_feature_usage_tenant_id_fk; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.feature_usage
    ADD CONSTRAINT product_feature_usage_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: features product_features_tenant_id_fk; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.features
    ADD CONSTRAINT product_features_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: metrics product_metrics_tenant_id_fk; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.metrics
    ADD CONSTRAINT product_metrics_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: roadmap product_roadmap_tenant_id_fk; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.roadmap
    ADD CONSTRAINT product_roadmap_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: user_feedback product_user_feedback_tenant_id_fk; Type: FK CONSTRAINT; Schema: product; Owner: -
--

ALTER TABLE ONLY product.user_feedback
    ADD CONSTRAINT product_user_feedback_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: contracts contracts_created_by_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT contracts_created_by_fkey FOREIGN KEY (created_by) REFERENCES hr.employees(employee_id);


--
-- Name: contracts contracts_team_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT contracts_team_id_fkey FOREIGN KEY (team_id) REFERENCES hr.departments(department_id);


--
-- Name: customer_communications customer_communications_account_manager_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_communications
    ADD CONSTRAINT customer_communications_account_manager_id_fkey FOREIGN KEY (account_manager_id) REFERENCES hr.employees(employee_id);


--
-- Name: customer_communications customer_communications_customer_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_communications
    ADD CONSTRAINT customer_communications_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: customer_communications customer_communications_engagement_manager_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_communications
    ADD CONSTRAINT customer_communications_engagement_manager_id_fkey FOREIGN KEY (engagement_manager_id) REFERENCES hr.employees(employee_id);


--
-- Name: customer_onboarding customer_onboarding_customer_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_onboarding
    ADD CONSTRAINT customer_onboarding_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: contracts fk_sales_contracts_customer_id_sales_customers; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT fk_sales_contracts_customer_id_sales_customers FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: contracts fk_sales_contracts_sales_rep_id_hr_employees; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT fk_sales_contracts_sales_rep_id_hr_employees FOREIGN KEY (sales_rep_id) REFERENCES hr.employees(employee_id);


--
-- Name: invoices fk_sales_invoices_customer_id_sales_customers; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.invoices
    ADD CONSTRAINT fk_sales_invoices_customer_id_sales_customers FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: invoices fk_sales_invoices_order_id_sales_orders; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.invoices
    ADD CONSTRAINT fk_sales_invoices_order_id_sales_orders FOREIGN KEY (order_id) REFERENCES sales.orders(order_id);


--
-- Name: orders fk_sales_orders_customer_id_sales_customers; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT fk_sales_orders_customer_id_sales_customers FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: orders fk_sales_orders_department_id_hr_departments; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT fk_sales_orders_department_id_hr_departments FOREIGN KEY (department_id) REFERENCES hr.departments(department_id);


--
-- Name: orders fk_sales_orders_sales_rep_id_hr_employees; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT fk_sales_orders_sales_rep_id_hr_employees FOREIGN KEY (sales_rep_id) REFERENCES hr.employees(employee_id);


--
-- Name: sales_pipeline fk_sales_sales_pipeline_customer_id_sales_customers; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.sales_pipeline
    ADD CONSTRAINT fk_sales_sales_pipeline_customer_id_sales_customers FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: sales_pipeline fk_sales_sales_pipeline_sales_rep_id_hr_employees; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.sales_pipeline
    ADD CONSTRAINT fk_sales_sales_pipeline_sales_rep_id_hr_employees FOREIGN KEY (sales_rep_id) REFERENCES hr.employees(employee_id);


--
-- Name: regions regions_parent_region_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.regions
    ADD CONSTRAINT regions_parent_region_id_fkey FOREIGN KEY (parent_region_id) REFERENCES sales.regions(region_id);


--
-- Name: contracts sales_contracts_business_unit_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT sales_contracts_business_unit_id_fk FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id) NOT VALID;


--
-- Name: contracts sales_contracts_customer_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT sales_contracts_customer_id_fk FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id) NOT VALID;


--
-- Name: contracts sales_contracts_organization_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT sales_contracts_organization_id_fk FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id) NOT VALID;


--
-- Name: contracts sales_contracts_sales_rep_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT sales_contracts_sales_rep_id_fk FOREIGN KEY (sales_rep_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: contracts sales_contracts_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contracts
    ADD CONSTRAINT sales_contracts_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: customer_communications sales_customer_communications_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_communications
    ADD CONSTRAINT sales_customer_communications_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: customer_onboarding sales_customer_onboarding_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customer_onboarding
    ADD CONSTRAINT sales_customer_onboarding_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: customers sales_customers_account_manager_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT sales_customers_account_manager_id_fk FOREIGN KEY (account_manager_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: customers sales_customers_business_unit_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT sales_customers_business_unit_id_fk FOREIGN KEY (business_unit_id) REFERENCES auth.business_units(business_unit_id) NOT VALID;


--
-- Name: customers sales_customers_organization_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT sales_customers_organization_id_fk FOREIGN KEY (organization_id) REFERENCES auth.organizations(organization_id) NOT VALID;


--
-- Name: customers sales_customers_parent_customer_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT sales_customers_parent_customer_id_fk FOREIGN KEY (parent_customer_id) REFERENCES sales.customers(customer_id) NOT VALID;


--
-- Name: customers sales_customers_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT sales_customers_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: invoices sales_invoices_contract_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.invoices
    ADD CONSTRAINT sales_invoices_contract_id_fk FOREIGN KEY (contract_id) REFERENCES sales.contracts(contract_id) NOT VALID;


--
-- Name: invoices sales_invoices_customer_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.invoices
    ADD CONSTRAINT sales_invoices_customer_id_fk FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id) NOT VALID;


--
-- Name: invoices sales_invoices_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.invoices
    ADD CONSTRAINT sales_invoices_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: orders sales_orders_customer_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT sales_orders_customer_id_fk FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id) NOT VALID;


--
-- Name: orders sales_orders_sales_rep_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT sales_orders_sales_rep_id_fk FOREIGN KEY (sales_rep_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: orders sales_orders_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT sales_orders_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: regions sales_regions_parent_region_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.regions
    ADD CONSTRAINT sales_regions_parent_region_id_fk FOREIGN KEY (parent_region_id) REFERENCES sales.regions(region_id) NOT VALID;


--
-- Name: regions sales_regions_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.regions
    ADD CONSTRAINT sales_regions_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: sales_pipeline sales_sales_pipeline_account_manager_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.sales_pipeline
    ADD CONSTRAINT sales_sales_pipeline_account_manager_id_fk FOREIGN KEY (account_manager_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: sales_pipeline sales_sales_pipeline_customer_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.sales_pipeline
    ADD CONSTRAINT sales_sales_pipeline_customer_id_fk FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id) NOT VALID;


--
-- Name: sales_pipeline sales_sales_pipeline_tenant_id_fk; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.sales_pipeline
    ADD CONSTRAINT sales_sales_pipeline_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: call_recordings call_recordings_agent_id_fkey; Type: FK CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE ONLY support.call_recordings
    ADD CONSTRAINT call_recordings_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES hr.employees(employee_id);


--
-- Name: call_recordings call_recordings_customer_id_fkey; Type: FK CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE ONLY support.call_recordings
    ADD CONSTRAINT call_recordings_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


--
-- Name: call_recordings call_recordings_supervisor_id_fkey; Type: FK CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE ONLY support.call_recordings
    ADD CONSTRAINT call_recordings_supervisor_id_fkey FOREIGN KEY (supervisor_id) REFERENCES hr.employees(employee_id);


--
-- Name: call_recordings support_call_recordings_agent_id_fk; Type: FK CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE ONLY support.call_recordings
    ADD CONSTRAINT support_call_recordings_agent_id_fk FOREIGN KEY (agent_id) REFERENCES hr.employees(employee_id) NOT VALID;


--
-- Name: call_recordings support_call_recordings_team_id_fk; Type: FK CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE ONLY support.call_recordings
    ADD CONSTRAINT support_call_recordings_team_id_fk FOREIGN KEY (team_id) REFERENCES hr.teams(team_id) NOT VALID;


--
-- Name: call_recordings support_call_recordings_tenant_id_fk; Type: FK CONSTRAINT; Schema: support; Owner: -
--

ALTER TABLE ONLY support.call_recordings
    ADD CONSTRAINT support_call_recordings_tenant_id_fk FOREIGN KEY (tenant_id) REFERENCES auth.tenants(tenant_id) NOT VALID;


--
-- Name: access_grants; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.access_grants ENABLE ROW LEVEL SECURITY;
--
-- Name: builds; Type: ROW SECURITY; Schema: engineering; Owner: -
--

ALTER TABLE engineering.builds ENABLE ROW LEVEL SECURITY;

--
-- Name: code_repository; Type: ROW SECURITY; Schema: engineering; Owner: -
--

ALTER TABLE engineering.code_repository ENABLE ROW LEVEL SECURITY;

--
-- Name: issues; Type: ROW SECURITY; Schema: engineering; Owner: -
--

ALTER TABLE engineering.issues ENABLE ROW LEVEL SECURITY;

--
-- Name: projects; Type: ROW SECURITY; Schema: engineering; Owner: -
--

ALTER TABLE engineering.projects ENABLE ROW LEVEL SECURITY;

--
-- Name: pull_requests; Type: ROW SECURITY; Schema: engineering; Owner: -
--

ALTER TABLE engineering.pull_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: releases; Type: ROW SECURITY; Schema: engineering; Owner: -
--

ALTER TABLE engineering.releases ENABLE ROW LEVEL SECURITY;

--
-- Name: tests; Type: ROW SECURITY; Schema: engineering; Owner: -
--

ALTER TABLE engineering.tests ENABLE ROW LEVEL SECURITY;

--
-- Name: balance_sheet; Type: ROW SECURITY; Schema: finance; Owner: -
--

ALTER TABLE finance.balance_sheet ENABLE ROW LEVEL SECURITY;

--
-- Name: bank_accounts; Type: ROW SECURITY; Schema: finance; Owner: -
--

ALTER TABLE finance.bank_accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: budget; Type: ROW SECURITY; Schema: finance; Owner: -
--

ALTER TABLE finance.budget ENABLE ROW LEVEL SECURITY;

--
-- Name: expenses; Type: ROW SECURITY; Schema: finance; Owner: -
--

ALTER TABLE finance.expenses ENABLE ROW LEVEL SECURITY;

--
-- Name: payroll; Type: ROW SECURITY; Schema: finance; Owner: -
--

ALTER TABLE finance.payroll ENABLE ROW LEVEL SECURITY;

--
-- Name: revenue; Type: ROW SECURITY; Schema: finance; Owner: -
--

ALTER TABLE finance.revenue ENABLE ROW LEVEL SECURITY;

--
-- Name: tax_records; Type: ROW SECURITY; Schema: finance; Owner: -
--

ALTER TABLE finance.tax_records ENABLE ROW LEVEL SECURITY;

--
-- Name: attendance; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.attendance ENABLE ROW LEVEL SECURITY;

--
-- Name: benefits; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.benefits ENABLE ROW LEVEL SECURITY;

--
-- Name: departments; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.departments ENABLE ROW LEVEL SECURITY;

--
-- Name: employee_allowances; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.employee_allowances ENABLE ROW LEVEL SECURITY;

--
-- Name: employees; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.employees ENABLE ROW LEVEL SECURITY;

--
-- Name: payroll; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.payroll ENABLE ROW LEVEL SECURITY;

--
-- Name: performance; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.performance ENABLE ROW LEVEL SECURITY;

--
-- Name: salary_history; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.salary_history ENABLE ROW LEVEL SECURITY;

--
-- Name: shifts; Type: ROW SECURITY; Schema: hr; Owner: -
--

ALTER TABLE hr.shifts ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs; Type: ROW SECURITY; Schema: operations; Owner: -
--

ALTER TABLE operations.audit_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: backups; Type: ROW SECURITY; Schema: operations; Owner: -
--

ALTER TABLE operations.backups ENABLE ROW LEVEL SECURITY;

--
-- Name: documents; Type: ROW SECURITY; Schema: operations; Owner: -
--

ALTER TABLE operations.documents ENABLE ROW LEVEL SECURITY;

--
-- Name: security_events; Type: ROW SECURITY; Schema: operations; Owner: -
--

ALTER TABLE operations.security_events ENABLE ROW LEVEL SECURITY;

--
-- Name: system_config; Type: ROW SECURITY; Schema: operations; Owner: -
--

ALTER TABLE operations.system_config ENABLE ROW LEVEL SECURITY;

--
-- Name: temporal_access; Type: ROW SECURITY; Schema: operations; Owner: -
--

ALTER TABLE operations.temporal_access ENABLE ROW LEVEL SECURITY;

--
-- Name: analytics; Type: ROW SECURITY; Schema: product; Owner: -
--

ALTER TABLE product.analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: feature_dependencies; Type: ROW SECURITY; Schema: product; Owner: -
--

ALTER TABLE product.feature_dependencies ENABLE ROW LEVEL SECURITY;

--
-- Name: feature_usage; Type: ROW SECURITY; Schema: product; Owner: -
--

ALTER TABLE product.feature_usage ENABLE ROW LEVEL SECURITY;

--
-- Name: features; Type: ROW SECURITY; Schema: product; Owner: -
--

ALTER TABLE product.features ENABLE ROW LEVEL SECURITY;

--
-- Name: metrics; Type: ROW SECURITY; Schema: product; Owner: -
--

ALTER TABLE product.metrics ENABLE ROW LEVEL SECURITY;

--
-- Name: roadmap; Type: ROW SECURITY; Schema: product; Owner: -
--

ALTER TABLE product.roadmap ENABLE ROW LEVEL SECURITY;

--
-- Name: user_feedback; Type: ROW SECURITY; Schema: product; Owner: -
--

ALTER TABLE product.user_feedback ENABLE ROW LEVEL SECURITY;

--
-- Name: contracts; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.contracts ENABLE ROW LEVEL SECURITY;

--
-- Name: customer_communications; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.customer_communications ENABLE ROW LEVEL SECURITY;

--
-- Name: customer_onboarding; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.customer_onboarding ENABLE ROW LEVEL SECURITY;

--
-- Name: customers; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

--
-- Name: invoices; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.invoices ENABLE ROW LEVEL SECURITY;

--
-- Name: orders; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.orders ENABLE ROW LEVEL SECURITY;

--
-- Name: sales_pipeline; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.sales_pipeline ENABLE ROW LEVEL SECURITY;

--
-- Name: call_recordings; Type: ROW SECURITY; Schema: support; Owner: -
--

ALTER TABLE support.call_recordings ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict zmy31IpEU25wUIuLqv8tcW0c4vxfKzYNSIKlfW67nptDtmSGL13AmjeaduVqdad
