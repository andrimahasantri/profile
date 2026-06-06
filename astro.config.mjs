import { defineConfig } from "astro/config";
import mdx from "@astrojs/mdx";
import m2dx from "astro-m2dx";
import sitemap from "@astrojs/sitemap";
import tailwind from "@astrojs/tailwind";
import rehypeExternalLinks from "rehype-external-links";
import fauxRemarkEmbedder from "@remark-embedder/core";
import fauxOembedTransformer from "@remark-embedder/transformer-oembed";
import { loadEnv } from "vite";
const remarkEmbedder = fauxRemarkEmbedder.default;
const oembedTransformer = fauxOembedTransformer.default;
import vue from "@astrojs/vue";
/** @type {import('astro-m2dx').Options} */
import icon from "astro-icon";
import netlify from "@astrojs/netlify";
import vercel from "@astrojs/vercel/serverless";
import node from "@astrojs/node";

// Load all env vars so we can pick the deploy target.
const env = loadEnv("", process.cwd(), "");

// SELFHOST=true -> Node standalone server (Docker/VPS, form/SSR tetap jalan)
// NETLIFY set   -> Netlify adapter
// default       -> Vercel serverless adapter
function getAdapter() {
  if (env.SELFHOST) return node({ mode: "standalone" });
  if (env.NETLIFY) return netlify();
  return vercel();
}

const m2dxOptions = {
  exportComponents: true,
  unwrapImages: true,
  autoImports: true,
};

// https://astro.build/config
export default defineConfig({
  site: "https://starfunnel.unfolding.io",
  output: "hybrid",
  adapter: getAdapter(),
  integrations: [
    icon(),
    mdx({}),
    sitemap(),
    tailwind(),
    vue({
      appEntrypoint: "/src/pages/_app",
    }),
  ],
  markdown: {
    extendDefaultPlugins: true,
    remarkPlugins: [
      [
        remarkEmbedder,
        {
          transformers: [oembedTransformer],
        },
      ],
      [m2dx, m2dxOptions],
    ],
    rehypePlugins: [
      [
        rehypeExternalLinks,
        {
          rel: ["nofollow"],
          target: ["_blank"],
        },
      ],
    ],
  },
  vite: {
    build: {
      rollupOptions: {
        external: [],
      },
      assetsInlineLimit: 10096,
    },
    ssr: {
      // Workaround until they support native ESM
      noExternal: ["vue3-popper"],
    },
  },
  build: {
    inlineStylesheets: "always",
  },
  prefetch: {
    defaultStrategy: "viewport",
  },
  scopedStyleStrategy: "attribute",
  image: {
    cache: true,
    service: {
      entrypoint: "./src/image-service/image-service",
    },
  },
});
