create type commonexternalproviders as enum ('easy_redmine');

alter type commonexternalproviders owner to relsys;

create type commonexternalentitytypes as enum ('project', 'user', 'project_task', 'worklog', 'comment', 'local_role');

alter type commonexternalentitytypes owner to relsys;

create type easyredmineinvestmentparententitytype as enum ('Issue', 'Project');

alter type easyredmineinvestmentparententitytype owner to relsys;

create type easyredmineinvestmentcategory as enum ('other_revenue', 'other_expense', 'expected_revenue', 'expected_expense');

alter type easyredmineinvestmentcategory owner to relsys;

create type userstatus as enum ('deleted', 'disabled', 'active');

alter type userstatus owner to relsys;

create type globalrole as enum ('administrator', 'project_manager', 'user', 'guest');

alter type globalrole owner to relsys;

create type taskstate as enum ('undefined', 'created', 'estimating_needed', 'estimating', 'estimating_completed', 'to_do', 'in_progress', 'user_testing', 'completed');

alter type taskstate owner to relsys;

create type taskrelationuserrole as enum ('author', 'coworker', 'assignee');

alter type taskrelationuserrole owner to relsys;

create type timerstate as enum ('not_started', 'timer_start', 'timer_paused', 'timer_resumed', 'timer_stop', 'work_completed');

alter type timerstate owner to relsys;

create type worklogtype as enum ('creation_log', 'journal', 'timer', 'incremental');

alter type worklogtype owner to relsys;

create table encryption_keys
(
	id varchar not null
		constraint encryption_keys_pkey
			primary key,
	key varchar not null,
	attached_entity_type varchar not null,
	attached_entity_id varchar not null,
	expired_date timestamp
);

alter table encryption_keys owner to relsys;

create table any_external_data
(
	id varchar not null
		constraint any_external_data_pkey
			primary key,
	tag varchar not null,
	name varchar not null,
	external_provider commonexternalproviders not null,
	external_source varchar not null,
	external_id varchar not null,
	jsonb_data jsonb
);

alter table any_external_data owner to relsys;

create table any_external_entities
(
	id varchar not null
		constraint any_external_entities_pkey
			primary key,
	entity_id varchar not null,
	entity_type commonexternalentitytypes not null,
	external_provider commonexternalproviders not null,
	external_source varchar not null,
	external_id varchar not null,
	external_additional_data jsonb,
	constraint __entity_id_type_provider_source_external_id_uk
		unique (entity_id, entity_type, external_provider, external_source, external_id)
);

alter table any_external_entities owner to relsys;

create table external_sources
(
	id varchar not null
		constraint external_sources_pkey
			primary key,
	external_provider commonexternalproviders not null,
	external_source varchar not null,
	api_key varchar not null,
	constraint __external_provider_and_source_uk
		unique (external_provider, external_source)
);

alter table external_sources owner to relsys;

create table user_identities
(
	id varchar not null
		constraint user_identities_pkey
			primary key,
	login varchar,
	password_hash varchar not null,
	expire_date timestamp
);

alter table user_identities owner to relsys;

create table users
(
	id varchar not null
		constraint users_pkey
			primary key,
	login varchar,
	firstname varchar,
	lastname varchar,
	email varchar
		constraint users_email_key
			unique,
	created_at timestamp not null,
	status userstatus not null,
	role globalrole not null
);

alter table users owner to relsys;

create table metamask_nonces
(
	wallet varchar not null
		constraint metamask_nonces_pkey
			primary key,
	nonce_type varchar not null,
	nonce varchar not null
);

alter table metamask_nonces owner to relsys;

create table blockchain_project_history
(
	history_id serial not null
		constraint blockchain_project_history_pkey
			primary key,
	history_type varchar,
	id varchar not null,
	author_id varchar,
	parent_id varchar,
	title varchar,
	description varchar,
	iteration integer not null,
	created_at timestamp not null,
	planned_completion_date timestamp not null,
	estimate_time double precision not null,
	work_time bigint,
	contract_address varchar,
	transaction varchar,
	external_source varchar,
	external_id varchar
);

alter table blockchain_project_history owner to relsys;

create table blockchain_project_task_history
(
	history_id serial not null
		constraint blockchain_project_task_history_pkey
			primary key,
	history_type varchar,
	id varchar not null,
	project_id varchar,
	parent_id varchar,
	author_id varchar not null,
	assignee_id varchar,
	title varchar not null,
	description varchar,
	tracker varchar,
	priority integer,
	iteration integer,
	estimate_time double precision,
	task_state taskstate,
	total_cost double precision,
	total_work_time bigint,
	created_at timestamp,
	updated_at timestamp,
	complete_date timestamp,
	transaction varchar,
	external_source varchar,
	external_id varchar
);

alter table blockchain_project_task_history owner to relsys;

create table blockchain_worklog_history
(
	history_id serial not null,
	history_type varchar,
	id varchar not null,
	project_id varchar,
	project_task_id varchar,
	author_id varchar not null,
	project_task_parent_id varchar,
	project_task_author_id varchar,
	project_task_assignee_id varchar,
	title varchar,
	description varchar,
	work_log_type worklogtype not null,
	tracker varchar,
	priority integer,
	iteration integer,
	estimate_time double precision not null,
	task_state taskstate not null,
	action_description varchar,
	action_cost double precision,
	action_work_time bigint,
	timer_state timerstate,
	created_at timestamp not null,
	date timestamp not null,
	transaction varchar,
	external_source varchar,
	external_id varchar,
	constraint blockchain_worklog_history_pkey
		primary key (history_id, id)
);

alter table blockchain_worklog_history owner to relsys;

create table blockchain_easy_redmine_investment_history
(
	history_id serial not null,
	history_type varchar,
	id varchar not null,
	project_id varchar,
	project_task_id varchar,
	parent_entity_type easyredmineinvestmentparententitytype not null,
	title varchar not null,
	description varchar,
	investment_category easyredmineinvestmentcategory not null,
	spent_on date not null,
	cost_without_vat double precision not null,
	cost_with_vat double precision not null,
	vat double precision not null,
	currency_code varchar not null,
	external_source varchar not null,
	external_id varchar not null,
	additional_data jsonb,
	transaction varchar,
	constraint blockchain_easy_redmine_investment_history_pkey
		primary key (history_id, id)
);

alter table blockchain_easy_redmine_investment_history owner to relsys;

create table sessions
(
	id varchar not null
		constraint sessions_pkey
			primary key
		constraint sessions_id_fkey
			references user_identities
				on delete restrict,
	start_date timestamp not null,
	expire_date timestamp,
	user_identity_id varchar not null,
	session_state varchar not null
);

alter table sessions owner to relsys;

create table task_encryption_templates
(
	id varchar not null
		constraint task_encryption_templates_pkey
			primary key,
	current_encryption_key_id varchar not null
		constraint task_encryption_templates_current_encryption_key_id_key
			unique
		constraint task_encryption_templates_current_encryption_key_id_fkey
			references encryption_keys,
	title_encrypt_state boolean,
	description_encrypt_state boolean,
	task_state_encrypt_state boolean,
	timer_state_encrypt_state boolean,
	priority_encrypt_state boolean,
	queue_encrypt_state boolean,
	is_daily_encrypt_state boolean,
	daily_queue_encrypt_state boolean,
	transaction_encrypt_state boolean,
	created_at_encrypt_state boolean,
	last_view_date_encrypt_state boolean,
	complete_date_encrypt_state boolean,
	iteration_encrypt_state boolean,
	total_cost_encrypt_state boolean,
	estimate_time_encrypt_state boolean,
	work_time_encrypt_state boolean,
	complete_description_encrypt_state boolean,
	external_source_encrypt_state boolean,
	external_id_encrypt_state boolean
);

alter table task_encryption_templates owner to relsys;

create table metamask_wallets
(
	wallet varchar not null
		constraint metamask_wallets_pkey
			primary key,
	user_id varchar not null
		constraint metamask_wallets_user_id_fkey
			references users
				on delete cascade,
	link_date timestamp not null,
	is_active boolean not null
);

alter table metamask_wallets owner to relsys;

create table projects
(
	id varchar not null
		constraint projects_pkey
			primary key,
	author_id varchar
		constraint projects_author_id_fkey
			references users
				on delete set null,
	parent_id varchar
		constraint projects_parent_id_fkey
			references projects
				on delete set null,
	title varchar,
	description varchar,
	created_at timestamp not null,
	planned_completion_date date,
	estimate_time double precision not null,
	work_time bigint,
	contract_address varchar,
	transaction varchar
);

alter table projects owner to relsys;

create table local_roles
(
	id varchar not null
		constraint local_roles_pkey
			primary key,
	title varchar not null,
	author_id varchar
		constraint local_roles_author_id_fkey
			references users
				on delete set null,
	registration_token_post boolean,
	projects_put boolean,
	projects_get_by_id boolean,
	projects_delete_by_id boolean,
	projects_users_by_id boolean,
	project_local_role_post boolean,
	project_local_role_put boolean,
	project_local_role_delete boolean,
	project_tasks_put boolean,
	project_tasks_get_by_id boolean,
	project_tasks_post boolean,
	project_tasks_delete boolean,
	project_tasks_personal_info_timer_put boolean,
	project_tasks_get_available_coworkers boolean,
	project_tasks_personal_info_post boolean,
	project_tasks_personal_info_delete boolean,
	users_project_relation_post boolean,
	users_project_relation_delete boolean
);

alter table local_roles owner to relsys;

create table user_settings
(
	id varchar not null
		constraint user_settings_pkey
			primary key,
	is_notifications boolean not null,
	is_mail_messaging boolean not null,
	user_id varchar not null
		constraint user_settings_user_id_fkey
			references users
				on delete cascade
);

alter table user_settings owner to relsys;

create table user_invitations
(
	id varchar not null
		constraint user_invitations_pkey
			primary key,
	inviter_user_id varchar not null
		constraint user_invitations_inviter_user_id_fkey
			references users
				on delete cascade
		constraint user_invitations_inviter_user_id_fkey1
			references users
				on delete cascade,
	invited_user_id varchar not null,
	registration_token varchar not null
);

alter table user_invitations owner to relsys;

create table user_projects_relations
(
	id varchar not null
		constraint user_projects_relations_pkey
			primary key,
	project_id varchar not null
		constraint user_projects_relations_project_id_fkey
			references projects
				on delete cascade,
	user_id varchar not null
		constraint user_projects_relations_user_id_fkey
			references users
				on delete cascade,
	local_role_id varchar not null
		constraint user_projects_relations_local_role_id_fkey
			references local_roles
				on delete cascade,
	constraint user_projects_relations_project_id_user_id_key
		unique (project_id, user_id)
);

alter table user_projects_relations owner to relsys;

create table project_tasks
(
	id varchar not null
		constraint project_tasks_pkey
			primary key,
	project_id varchar
		constraint project_tasks_project_id_fkey
			references projects
				on delete cascade,
	parent_id varchar
		constraint project_tasks_parent_id_fkey
			references project_tasks
				on delete set null,
	author_id varchar not null
		constraint project_tasks_author_id_fkey
			references users
				on delete set null,
	assignee_id varchar
		constraint project_tasks_assignee_id_fkey
			references users
				on delete set null,
	title varchar not null,
	description varchar,
	tracker varchar,
	priority integer,
	iteration integer,
	estimate_time double precision,
	task_state taskstate,
	total_cost double precision,
	total_work_time bigint,
	created_at timestamp,
	updated_at timestamp,
	complete_date timestamp,
	transaction varchar
);

alter table project_tasks owner to relsys;

create table easy_redmine_investments
(
	id varchar not null
		constraint easy_redmine_investments_pkey
			primary key,
	project_id varchar
		constraint easy_redmine_investments_project_id_fkey
			references projects
				on delete cascade,
	project_task_id varchar
		constraint easy_redmine_investments_project_task_id_fkey
			references project_tasks
				on delete cascade,
	parent_entity_type easyredmineinvestmentparententitytype not null,
	title varchar not null,
	description varchar,
	investment_category easyredmineinvestmentcategory not null,
	spent_on date not null,
	cost_without_vat double precision not null,
	cost_with_vat double precision not null,
	vat double precision not null,
	currency_code varchar not null,
	external_source varchar not null,
	external_id varchar not null,
	additional_data jsonb,
	transaction varchar
);

alter table easy_redmine_investments owner to relsys;

create table personal_task_info
(
	id varchar not null
		constraint personal_task_info_pkey
			primary key,
	project_task_id varchar not null
		constraint personal_task_info_project_task_id_fkey
			references project_tasks
				on delete cascade,
	user_id varchar not null
		constraint personal_task_info_user_id_fkey
			references users
				on delete cascade,
	role taskrelationuserrole not null,
	timer_state timerstate,
	user_work_time bigint,
	user_cost double precision,
	priority integer,
	position integer,
	is_daily boolean,
	daily_position integer,
	constraint personal_task_info_project_task_id_user_id_key
		unique (project_task_id, user_id)
);

alter table personal_task_info owner to relsys;

create table work_logs
(
	id varchar not null
		constraint work_logs_pkey
			primary key,
	project_id varchar
		constraint work_logs_project_id_fkey
			references projects
				on delete cascade,
	project_task_id varchar
		constraint work_logs_project_task_id_fkey
			references project_tasks
				on delete set null,
	author_id varchar not null
		constraint work_logs_author_id_fkey
			references users
				on delete set null,
	project_task_parent_id varchar
		constraint work_logs_project_task_parent_id_fkey
			references project_tasks
				on delete set null,
	project_task_author_id varchar
		constraint work_logs_project_task_author_id_fkey
			references users
				on delete set null,
	project_task_assignee_id varchar
		constraint work_logs_project_task_assignee_id_fkey
			references users
				on delete set null,
	title varchar,
	description varchar,
	work_log_type worklogtype not null,
	tracker varchar,
	priority integer,
	iteration integer,
	estimate_time double precision not null,
	task_state taskstate not null,
	action_description varchar,
	action_cost double precision,
	action_work_time bigint,
	timer_state timerstate,
	created_at timestamp not null,
	date timestamp not null,
	transaction varchar
);

alter table work_logs owner to relsys;

create table comments
(
	id varchar not null
		constraint comments_pkey
			primary key,
	project_id varchar
		constraint comments_project_id_fkey
			references projects
				on delete set null,
	project_task_id varchar
		constraint comments_project_task_id_fkey
			references project_tasks
				on delete set null,
	author_id varchar not null
		constraint comments_author_id_fkey
			references users
				on delete set null,
	text varchar,
	created_at timestamp not null,
	transaction varchar
);

alter table comments owner to relsys;

create table registration_tokens
(
	id varchar not null
		constraint registration_tokens_pkey
			primary key,
	author_id varchar not null
		constraint registration_tokens_author_id_fkey
			references users
				on delete cascade,
	author_first_name varchar not null,
	author_last_name varchar not null,
	project_task_id varchar not null
		constraint registration_tokens_project_task_id_fkey
			references project_tasks
				on delete cascade,
	project_task_title varchar not null,
	url varchar not null,
	token varchar not null,
	is_anonymous boolean,
	expire_date timestamp,
	emails_to_register character varying[]
);

alter table registration_tokens owner to relsys;

