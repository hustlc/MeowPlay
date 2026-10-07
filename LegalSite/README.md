# Publish the MeowPlay official site

`LegalSite` is the static website for MeowPlay, including the official homepage, Privacy Policy, Terms of Use, and Support page. It is prepared for Cloudflare Pages and does not require a server or database.

`play.html` is the browser soundboard. It loads the 19 launch sounds from
`audio/` and keeps favorites in the visitor's browser with local storage.

The public support page is `https://ko-fi.com/hustlicong`. Keep this link
public; never add PayPal credentials or Ko-fi account tokens to the repository.

## Important

`https://gogo-9eq.pages.dev/` is an existing Go-learning site and must not be replaced or reused for MeowPlay. Create a separate Cloudflare Pages project, preferably named `meowplay-official`.

The intended URLs are:

- `https://meowplay-official.pages.dev/`
- `https://meowplay-official.pages.dev/privacy.html`
- `https://meowplay-official.pages.dev/terms.html`
- `https://meowplay-official.pages.dev/support.html`

Cloudflare may assign a different `pages.dev` address if that project name is unavailable. After deployment, update the three URLs in `MeowPlay/App/AppConfiguration.swift` and the App Store Connect legal links to the actual address.

## Cloudflare Pages deployment

1. Sign in to the Cloudflare dashboard under the publisher account.
2. Open **Workers & Pages** and create a new **Pages** project.
3. Name it `meowplay-official` or another available MeowPlay-specific name.
4. Choose **Direct Upload**.
5. Upload the contents of this `LegalSite` directory, not the parent project directory.
6. Deploy and open the homepage, Privacy, Terms, and Support URLs.
7. Confirm the page footer says `vista intelligence` and Support shows `licong28@hotmail.com`.
8. Replace the three URLs in `AppConfiguration.swift` if Cloudflare used a different project name.

The website is static. The deployment output is this directory itself; there is no build command and no environment variable required.
