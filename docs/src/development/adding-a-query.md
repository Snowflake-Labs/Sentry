<!-- markdownlint-disable MD033 -->
The process to add an example query to a page in Sentry:

1. Create a new directory under `src/queries`, for example "`demo_query`"
2. Add the query `.sql` file in the new directory. It should have the same name
   as the directory ("`demo_query.sql`")
3. Add a `README.md` file for the query with some front matter (see the example
   patch below)
4. Add a `Query` object to `src/common/queries.py`. The argument should be the
   name of the directory (`Query("demo_query")`)
5. Add a `Tile` object to a collection of tiles in `src/common/tiles.py` (see
   the example patch below)

By default a query will be rendered as a table. You can customize the query
display by passing extra `render_f` argument (see examples in `tiles.py`).

<details>
<summary>Sample diff</summary>

```patch
diff --git a/src/common/queries.py b/src/common/queries.py
index 0976a14..0aeab41 100644
--- a/src/common/queries.py
+++ b/src/common/queries.py
@@ -71,3 +71,5 @@ STATIC_CREDS = Query("may30_ttps_guidance_static_creds")
 QUERY_HISTORY = Query("may30_ttps_guidance_query_history")
 
 ANOMALOUS_APPLICATION_ACCESS = Query("may30_ttps_guidance_anomalous_application_access")
+
+DEMO_QUERY = Query("demo_query")
diff --git a/src/common/tiles.py b/src/common/tiles.py
index 73ffa1b..20e2de3 100644
--- a/src/common/tiles.py
+++ b/src/common/tiles.py
@@ -79,6 +79,7 @@ altair_chart = partial(
 )  # NOTE: theme="streamlit" is default
 
 AuthTiles = _mk_tiles(
+    queries.DEMO_QUERY,
     {
         "query": NUM_FAILURES,
         "render_f": lambda data: altair_chart(
diff --git a/src/queries/demo_query/README.md b/src/queries/demo_query/README.md
new file mode 100644
index 0000000..aeff47f
--- /dev/null
+++ b/src/queries/demo_query/README.md
@@ -0,0 +1,7 @@
+---
+title: A demo query
+Tile Identifier: AUTH-0
+Dashboard: Authentication
+---
+
+Here be dragons
diff --git a/src/queries/demo_query/demo_query.sql b/src/queries/demo_query/demo_query.sql
new file mode 100644
index 0000000..2e3761f
--- /dev/null
+++ b/src/queries/demo_query/demo_query.sql
@@ -0,0 +1 @@
+SELECT 1
```

</details>
