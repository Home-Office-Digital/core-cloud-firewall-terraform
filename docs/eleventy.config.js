import { govukEleventyPlugin } from "@x-govuk/govuk-eleventy-plugin";

export default function eleventyConfigSetup(eleventyConfig) {

  // Automatically derives repo name from GITHUB_REPOSITORY or falls back to package.json name
  const [githubRepositoryOwner, githubRepositoryName] = (process.env.GITHUB_REPOSITORY || '').split('/');
  const repoOwner = githubRepositoryOwner || 'Home-Office-Digital';
  const repoName = githubRepositoryName || process.env.npm_package_name || '';

  const url = '/core-cloud-firewall-terraform/';
  const pathPrefix = '/core-cloud-firewall-terraform/';

  eleventyConfig.addPassthroughCopy({ "assets/logos": "assets/logos" });

  const xgovukPluginOptions = {
    stylesheets: ['/styles/base.css'],
    templates: {
      searchIndex: {
        permalink: '/search.json'
      }
    },
    icons: {
      mask: '/assets/logos/ho-mask-icon.svg',
      shortcut: '/assets/logos/ho-favicon.ico',
      touch: '/assets/logos/ho-apple-touch-icon.png'
    },
    opengraphImageUrl: '/assets/logos/ho-opengraph-image.png',
    homeKey: 'Home',
    header: {
      logotype: {
        html:
          '<span class="govuk-header__logotype">' +
          '  <img src="/assets/logos/ho_logo.svg" height="34px" alt="Home Office Logo">' +
          '  <span class="govuk-header__logotype-text">Home Office</span>' +
          '</span>'
      },
      productName: 'Core Cloud',
      organisationName: 'Home Office',
      search: {
        label: 'Search site',
        indexPath: '/search.json',
        sitemapPath: '/sitemap.html'
      }
    },
    footer: {
      copyright: {
        html: `© <a class="govuk-footer__link" href="https://github.com/${repoOwner}/${repoName}/blob/main/LICENSE.md">Crown Copyright (Home Office)</a>`
      },
    },
    pathPrefix,
    url,
  };

  eleventyConfig.addPlugin(govukEleventyPlugin, xgovukPluginOptions);

  return {
    pathPrefix,
    dataTemplateEngine: 'njk',
    htmlTemplateEngine: 'njk',
    markdownTemplateEngine: 'njk',
    dir: {
      input: './',
    }
  };
}
