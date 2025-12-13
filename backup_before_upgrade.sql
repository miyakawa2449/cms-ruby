--
-- PostgreSQL database dump
--

\restrict gJE46nvh9xpTqErOkWALeNisjpmTh3xZVJ9bxGGs7olsF4XSMceMfo78UBrh6uo

-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    record_id bigint NOT NULL,
    record_type character varying NOT NULL
);


ALTER TABLE public.active_storage_attachments OWNER TO portfolio;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_attachments_id_seq OWNER TO portfolio;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    content_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    filename character varying NOT NULL,
    key character varying NOT NULL,
    metadata text,
    service_name character varying NOT NULL
);


ALTER TABLE public.active_storage_blobs OWNER TO portfolio;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_blobs_id_seq OWNER TO portfolio;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


ALTER TABLE public.active_storage_variant_records OWNER TO portfolio;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNER TO portfolio;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.admin_users (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    remember_created_at timestamp(6) without time zone,
    reset_password_sent_at timestamp(6) without time zone,
    reset_password_token character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_users OWNER TO portfolio;

--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_users_id_seq OWNER TO portfolio;

--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO portfolio;

--
-- Name: article_categories; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.article_categories (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    category_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.article_categories OWNER TO portfolio;

--
-- Name: article_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.article_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_categories_id_seq OWNER TO portfolio;

--
-- Name: article_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.article_categories_id_seq OWNED BY public.article_categories.id;


--
-- Name: article_tags; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.article_tags (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    tag_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.article_tags OWNER TO portfolio;

--
-- Name: article_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.article_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_tags_id_seq OWNER TO portfolio;

--
-- Name: article_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.article_tags_id_seq OWNED BY public.article_tags.id;


--
-- Name: articles; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.articles (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    content text NOT NULL,
    content_html text,
    created_at timestamp(6) without time zone NOT NULL,
    demo_url character varying,
    excerpt text,
    github_url character varying,
    meta_description character varying(500),
    meta_keywords character varying(500),
    og_description character varying(500),
    og_title character varying(255),
    published_at timestamp(6) without time zone,
    slug character varying(255) NOT NULL,
    status character varying(50) DEFAULT 'draft'::character varying,
    tech_stack text,
    title character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    work_type character varying
);


ALTER TABLE public.articles OWNER TO portfolio;

--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.articles_id_seq OWNER TO portfolio;

--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.articles_id_seq OWNED BY public.articles.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    article_count integer DEFAULT 0,
    color character varying(7),
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    icon character varying(50),
    name character varying(100) NOT NULL,
    parent_id bigint,
    "position" integer DEFAULT 0,
    slug character varying(100) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.categories OWNER TO portfolio;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO portfolio;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.contacts (
    id bigint NOT NULL,
    assigned_to_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying,
    ip_address inet,
    is_spam boolean DEFAULT false,
    message text,
    name character varying,
    notes text,
    referrer character varying,
    replied_at timestamp without time zone,
    spam_score numeric(3,2),
    status character varying DEFAULT 'unread'::character varying,
    subject character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    user_agent text
);


ALTER TABLE public.contacts OWNER TO portfolio;

--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contacts_id_seq OWNER TO portfolio;

--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: my_story_sections; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.my_story_sections (
    id bigint NOT NULL,
    achievements text,
    additional_data jsonb DEFAULT '{}'::jsonb,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    quote text,
    section_type character varying NOT NULL,
    skills text,
    subtitle character varying,
    title character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.my_story_sections OWNER TO portfolio;

--
-- Name: my_story_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.my_story_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.my_story_sections_id_seq OWNER TO portfolio;

--
-- Name: my_story_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.my_story_sections_id_seq OWNED BY public.my_story_sections.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO portfolio;

--
-- Name: section_contents; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.section_contents (
    id bigint NOT NULL,
    backend_skills text,
    badge_text character varying,
    career_description text,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    core_skills text,
    created_at timestamp(6) without time zone NOT NULL,
    cta_button_text character varying,
    cta_description text,
    cta_primary_text character varying,
    cta_primary_url character varying,
    cta_secondary_text character varying,
    cta_secondary_url character varying,
    experience_text text,
    frontend_skills text,
    is_active boolean DEFAULT false,
    main_message text,
    main_title text,
    phase1_description text,
    phase1_period character varying,
    phase1_title character varying,
    phase1_year character varying,
    phase2_description text,
    phase2_period character varying,
    phase2_title character varying,
    phase2_year character varying,
    phase3_description text,
    phase3_period character varying,
    phase3_title character varying,
    phase3_year character varying,
    profile_text text,
    published_at timestamp(6) without time zone,
    published_by bigint,
    section_id bigint NOT NULL,
    sub_message text,
    sub_title text,
    updated_at timestamp(6) without time zone NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.section_contents OWNER TO portfolio;

--
-- Name: section_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.section_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.section_contents_id_seq OWNER TO portfolio;

--
-- Name: section_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.section_contents_id_seq OWNED BY public.section_contents.id;


--
-- Name: sections; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.sections (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    display_name character varying(100) NOT NULL,
    is_visible boolean DEFAULT true,
    name character varying(100) NOT NULL,
    "position" integer DEFAULT 0,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.sections OWNER TO portfolio;

--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sections_id_seq OWNER TO portfolio;

--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.sections_id_seq OWNED BY public.sections.id;


--
-- Name: slack_notifications; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.slack_notifications (
    id bigint NOT NULL,
    channel character varying,
    created_at timestamp(6) without time zone NOT NULL,
    error_message text,
    notification_type character varying,
    payload text,
    reference_id bigint,
    reference_type character varying,
    retry_count integer DEFAULT 0,
    sent_at timestamp without time zone,
    status character varying DEFAULT 'pending'::character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    webhook_url character varying
);


ALTER TABLE public.slack_notifications OWNER TO portfolio;

--
-- Name: slack_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.slack_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.slack_notifications_id_seq OWNER TO portfolio;

--
-- Name: slack_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.slack_notifications_id_seq OWNED BY public.slack_notifications.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    article_count integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying(50) NOT NULL,
    slug character varying(50) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.tags OWNER TO portfolio;

--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tags_id_seq OWNER TO portfolio;

--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: test_items; Type: TABLE; Schema: public; Owner: portfolio
--

CREATE TABLE public.test_items (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.test_items OWNER TO portfolio;

--
-- Name: test_items_id_seq; Type: SEQUENCE; Schema: public; Owner: portfolio
--

CREATE SEQUENCE public.test_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.test_items_id_seq OWNER TO portfolio;

--
-- Name: test_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: portfolio
--

ALTER SEQUENCE public.test_items_id_seq OWNED BY public.test_items.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: article_categories id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_categories ALTER COLUMN id SET DEFAULT nextval('public.article_categories_id_seq'::regclass);


--
-- Name: article_tags id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_tags ALTER COLUMN id SET DEFAULT nextval('public.article_tags_id_seq'::regclass);


--
-- Name: articles id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.articles ALTER COLUMN id SET DEFAULT nextval('public.articles_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: my_story_sections id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.my_story_sections ALTER COLUMN id SET DEFAULT nextval('public.my_story_sections_id_seq'::regclass);


--
-- Name: section_contents id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.section_contents ALTER COLUMN id SET DEFAULT nextval('public.section_contents_id_seq'::regclass);


--
-- Name: sections id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.sections ALTER COLUMN id SET DEFAULT nextval('public.sections_id_seq'::regclass);


--
-- Name: slack_notifications id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.slack_notifications ALTER COLUMN id SET DEFAULT nextval('public.slack_notifications_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: test_items id; Type: DEFAULT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.test_items ALTER COLUMN id SET DEFAULT nextval('public.test_items_id_seq'::regclass);


--
-- Data for Name: active_storage_attachments; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.active_storage_attachments (id, blob_id, created_at, name, record_id, record_type) FROM stdin;
\.


--
-- Data for Name: active_storage_blobs; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.active_storage_blobs (id, byte_size, checksum, content_type, created_at, filename, key, metadata, service_name) FROM stdin;
\.


--
-- Data for Name: active_storage_variant_records; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.active_storage_variant_records (id, blob_id, variation_digest) FROM stdin;
\.


--
-- Data for Name: admin_users; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.admin_users (id, created_at, email, encrypted_password, remember_created_at, reset_password_sent_at, reset_password_token, updated_at) FROM stdin;
1	2025-12-12 11:36:47.833065	admin@portfolio.dev	$2a$12$IFbWRoRg7bIHVoXGFUij7usXM9HiN0Holj8tt7k8cH1.xnDhAMfy6	\N	\N	\N	2025-12-12 11:36:47.833065
\.


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	development	2025-12-12 11:36:42.496737	2025-12-12 11:36:42.496738
schema_sha1	7d72263f24daf2c1bd09063b68d5fa66ebd819d4	2025-12-12 11:36:42.498266	2025-12-12 11:36:42.498266
\.


--
-- Data for Name: article_categories; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.article_categories (id, article_id, category_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: article_tags; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.article_tags (id, article_id, created_at, tag_id, updated_at) FROM stdin;
\.


--
-- Data for Name: articles; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.articles (id, admin_user_id, content, content_html, created_at, demo_url, excerpt, github_url, meta_description, meta_keywords, og_description, og_title, published_at, slug, status, tech_stack, title, updated_at, work_type) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.categories (id, article_count, color, created_at, description, icon, name, parent_id, "position", slug, updated_at) FROM stdin;
1	0	#8B5CF6	2025-12-12 11:36:47.8512	プロジェクト実績やポートフォリオ作品を紹介	\N	実績・作品	\N	0	works	2025-12-12 11:36:47.8512
2	0	#3B82F6	2025-12-12 11:36:47.857121	技術情報や開発ノウハウを共有	\N	技術ブログ	\N	0	tech-blog	2025-12-12 11:36:47.857121
3	0	#10B981	2025-12-12 11:36:47.870546	開発プロセスや学習記録	\N	開発ログ	\N	0	dev-log	2025-12-12 11:36:47.870546
4	0	#6B7280	2025-12-12 11:36:47.879943	その他の話題	\N	雑記	\N	0	misc	2025-12-12 11:36:47.879943
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.contacts (id, assigned_to_id, created_at, email, ip_address, is_spam, message, name, notes, referrer, replied_at, spam_score, status, subject, updated_at, user_agent) FROM stdin;
\.


--
-- Data for Name: my_story_sections; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.my_story_sections (id, achievements, additional_data, content, created_at, is_active, "position", quote, section_type, skills, subtitle, title, updated_at) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.schema_migrations (version) FROM stdin;
20251212060323
20251212050458
20251211071452
20251211065843
20251211064248
20251211052557
20251205094022
20251205092517
20251205012726
20251203055832
20251203055827
20251203055818
20251203055803
20251203055709
20251203055427
20251203055401
20251203051618
20251213033842
\.


--
-- Data for Name: section_contents; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.section_contents (id, backend_skills, badge_text, career_description, content, core_skills, created_at, cta_button_text, cta_description, cta_primary_text, cta_primary_url, cta_secondary_text, cta_secondary_url, experience_text, frontend_skills, is_active, main_message, main_title, phase1_description, phase1_period, phase1_title, phase1_year, phase2_description, phase2_period, phase2_title, phase2_year, phase3_description, phase3_period, phase3_title, phase3_year, profile_text, published_at, published_by, section_id, sub_message, sub_title, updated_at, version) FROM stdin;
\.


--
-- Data for Name: sections; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.sections (id, created_at, display_name, is_visible, name, "position", updated_at) FROM stdin;
1	2025-12-12 11:36:47.890586	ヒーロー	t	hero	1	2025-12-12 11:36:47.890586
2	2025-12-12 11:36:47.894838	About	t	about	2	2025-12-12 11:36:47.894838
3	2025-12-12 11:36:47.905665	Service	t	service	3	2025-12-12 11:36:47.905665
4	2025-12-12 11:36:47.911217	My Story	t	my-story	4	2025-12-12 11:36:47.911217
5	2025-12-12 11:36:47.914593	Works	t	works	5	2025-12-12 11:36:47.914593
6	2025-12-12 11:36:47.918098	Blog	t	blog	6	2025-12-12 11:36:47.918098
7	2025-12-12 11:36:47.924279	Contact	t	contact	7	2025-12-12 11:36:47.924279
\.


--
-- Data for Name: slack_notifications; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.slack_notifications (id, channel, created_at, error_message, notification_type, payload, reference_id, reference_type, retry_count, sent_at, status, updated_at, webhook_url) FROM stdin;
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.tags (id, article_count, created_at, name, slug, updated_at) FROM stdin;
\.


--
-- Data for Name: test_items; Type: TABLE DATA; Schema: public; Owner: portfolio
--

COPY public.test_items (id, name, description, created_at, updated_at) FROM stdin;
1	Sample Item 1	Test data for debugging	2025-12-13 03:43:41.286278	2025-12-13 03:43:41.286278
2	Sample Item 2	Another test data	2025-12-13 03:43:41.291985	2025-12-13 03:43:41.291985
\.


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.active_storage_attachments_id_seq', 1, false);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.active_storage_blobs_id_seq', 1, false);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.active_storage_variant_records_id_seq', 1, false);


--
-- Name: admin_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.admin_users_id_seq', 1, true);


--
-- Name: article_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.article_categories_id_seq', 1, false);


--
-- Name: article_tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.article_tags_id_seq', 1, false);


--
-- Name: articles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.articles_id_seq', 1, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.categories_id_seq', 4, true);


--
-- Name: contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.contacts_id_seq', 1, false);


--
-- Name: my_story_sections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.my_story_sections_id_seq', 1, false);


--
-- Name: section_contents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.section_contents_id_seq', 1, false);


--
-- Name: sections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.sections_id_seq', 7, true);


--
-- Name: slack_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.slack_notifications_id_seq', 1, false);


--
-- Name: tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.tags_id_seq', 1, false);


--
-- Name: test_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: portfolio
--

SELECT pg_catalog.setval('public.test_items_id_seq', 2, true);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: article_categories article_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_categories
    ADD CONSTRAINT article_categories_pkey PRIMARY KEY (id);


--
-- Name: article_tags article_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_tags
    ADD CONSTRAINT article_tags_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: my_story_sections my_story_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.my_story_sections
    ADD CONSTRAINT my_story_sections_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: section_contents section_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.section_contents
    ADD CONSTRAINT section_contents_pkey PRIMARY KEY (id);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: slack_notifications slack_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.slack_notifications
    ADD CONSTRAINT slack_notifications_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: test_items test_items_pkey; Type: CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.test_items
    ADD CONSTRAINT test_items_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_admin_users_on_email; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_admin_users_on_email ON public.admin_users USING btree (email);


--
-- Name: index_admin_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_admin_users_on_reset_password_token ON public.admin_users USING btree (reset_password_token);


--
-- Name: index_article_categories_on_article_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_article_categories_on_article_id ON public.article_categories USING btree (article_id);


--
-- Name: index_article_categories_on_article_id_and_category_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_article_categories_on_article_id_and_category_id ON public.article_categories USING btree (article_id, category_id);


--
-- Name: index_article_categories_on_category_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_article_categories_on_category_id ON public.article_categories USING btree (category_id);


--
-- Name: index_article_tags_on_article_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_article_tags_on_article_id ON public.article_tags USING btree (article_id);


--
-- Name: index_article_tags_on_article_id_and_tag_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_article_tags_on_article_id_and_tag_id ON public.article_tags USING btree (article_id, tag_id);


--
-- Name: index_article_tags_on_tag_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_article_tags_on_tag_id ON public.article_tags USING btree (tag_id);


--
-- Name: index_articles_on_admin_user_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_articles_on_admin_user_id ON public.articles USING btree (admin_user_id);


--
-- Name: index_articles_on_published_at; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_articles_on_published_at ON public.articles USING btree (published_at);


--
-- Name: index_articles_on_slug; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_articles_on_slug ON public.articles USING btree (slug);


--
-- Name: index_articles_on_status; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_articles_on_status ON public.articles USING btree (status);


--
-- Name: index_articles_on_status_and_published_at; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_articles_on_status_and_published_at ON public.articles USING btree (status, published_at);


--
-- Name: index_categories_on_name; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_categories_on_name ON public.categories USING btree (name);


--
-- Name: index_categories_on_parent_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_categories_on_parent_id ON public.categories USING btree (parent_id);


--
-- Name: index_categories_on_position; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_categories_on_position ON public.categories USING btree ("position");


--
-- Name: index_categories_on_slug; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);


--
-- Name: index_contacts_on_assigned_to_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_contacts_on_assigned_to_id ON public.contacts USING btree (assigned_to_id);


--
-- Name: index_contacts_on_created_at; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_contacts_on_created_at ON public.contacts USING btree (created_at);


--
-- Name: index_contacts_on_email; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_contacts_on_email ON public.contacts USING btree (email);


--
-- Name: index_contacts_on_status; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_contacts_on_status ON public.contacts USING btree (status);


--
-- Name: index_my_story_sections_on_additional_data; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_my_story_sections_on_additional_data ON public.my_story_sections USING gin (additional_data);


--
-- Name: index_my_story_sections_on_is_active; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_my_story_sections_on_is_active ON public.my_story_sections USING btree (is_active);


--
-- Name: index_my_story_sections_on_is_active_and_position; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_my_story_sections_on_is_active_and_position ON public.my_story_sections USING btree (is_active, "position");


--
-- Name: index_my_story_sections_on_position; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_my_story_sections_on_position ON public.my_story_sections USING btree ("position");


--
-- Name: index_my_story_sections_on_section_type; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_my_story_sections_on_section_type ON public.my_story_sections USING btree (section_type);


--
-- Name: index_section_contents_on_content; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_section_contents_on_content ON public.section_contents USING gin (content);


--
-- Name: index_section_contents_on_published_by; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_section_contents_on_published_by ON public.section_contents USING btree (published_by);


--
-- Name: index_section_contents_on_section_id; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_section_contents_on_section_id ON public.section_contents USING btree (section_id);


--
-- Name: index_section_contents_on_section_id_and_version; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_section_contents_on_section_id_and_version ON public.section_contents USING btree (section_id, version);


--
-- Name: index_sections_on_name; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_sections_on_name ON public.sections USING btree (name);


--
-- Name: index_sections_on_position; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_sections_on_position ON public.sections USING btree ("position");


--
-- Name: index_slack_notifications_on_created_at; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_slack_notifications_on_created_at ON public.slack_notifications USING btree (created_at);


--
-- Name: index_slack_notifications_on_notification_type; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_slack_notifications_on_notification_type ON public.slack_notifications USING btree (notification_type);


--
-- Name: index_slack_notifications_on_status; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE INDEX index_slack_notifications_on_status ON public.slack_notifications USING btree (status);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tags_on_slug; Type: INDEX; Schema: public; Owner: portfolio
--

CREATE UNIQUE INDEX index_tags_on_slug ON public.tags USING btree (slug);


--
-- Name: articles fk_rails_4047679ba3; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT fk_rails_4047679ba3 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- Name: article_tags fk_rails_646e8d3122; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_tags
    ADD CONSTRAINT fk_rails_646e8d3122 FOREIGN KEY (article_id) REFERENCES public.articles(id);


--
-- Name: article_categories fk_rails_6f9552b855; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_categories
    ADD CONSTRAINT fk_rails_6f9552b855 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: categories fk_rails_82f48f7407; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_82f48f7407 FOREIGN KEY (parent_id) REFERENCES public.categories(id);


--
-- Name: contacts fk_rails_91dac45fd4; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT fk_rails_91dac45fd4 FOREIGN KEY (assigned_to_id) REFERENCES public.admin_users(id);


--
-- Name: article_categories fk_rails_9681f08b87; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_categories
    ADD CONSTRAINT fk_rails_9681f08b87 FOREIGN KEY (article_id) REFERENCES public.articles(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: section_contents fk_rails_9f50e92fc0; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.section_contents
    ADD CONSTRAINT fk_rails_9f50e92fc0 FOREIGN KEY (published_by) REFERENCES public.admin_users(id) ON DELETE SET NULL;


--
-- Name: article_tags fk_rails_b651172c61; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.article_tags
    ADD CONSTRAINT fk_rails_b651172c61 FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: section_contents fk_rails_cf278257a7; Type: FK CONSTRAINT; Schema: public; Owner: portfolio
--

ALTER TABLE ONLY public.section_contents
    ADD CONSTRAINT fk_rails_cf278257a7 FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- PostgreSQL database dump complete
--

\unrestrict gJE46nvh9xpTqErOkWALeNisjpmTh3xZVJ9bxGGs7olsF4XSMceMfo78UBrh6uo

