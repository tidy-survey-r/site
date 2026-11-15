# Post-render script: builds the link-preview image from _social/card.html.
#
# Screenshots the card with headless Chrome and saves it as
# <output dir>/images/social-preview.png, the image the Open Graph /
# Twitter tags point at (see `image:` in _quarto.yml and page front matter).
#
# Runs only on a full-site render (as on GitHub Actions), not on
# single-page renders or `quarto preview`. If Chrome can't be found it
# prints a warning and lets the render finish without the image.
# Set CHROME_PATH to point at a specific browser.

if (!identical(Sys.getenv("QUARTO_PROJECT_RENDER_ALL"), "1")) quit(save = "no")

find_chrome <- function() {
  candidates <- c(
    Sys.getenv("CHROME_PATH"),
    Sys.which(c("google-chrome", "google-chrome-stable", "chromium",
                "chromium-browser", "chrome", "msedge")),
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
    file.path(Sys.getenv("LOCALAPPDATA"), "Google/Chrome/Application/chrome.exe"),
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(candidates)) candidates[[1]] else NA_character_
}

card    <- normalizePath("_social/card.html", winslash = "/", mustWork = TRUE)
out_dir <- file.path(Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", "_site"), "images")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out     <- file.path(normalizePath(out_dir, winslash = "/"), "social-preview.png")

chrome <- find_chrome()
if (is.na(chrome)) {
  message("WARNING: [social card] Chrome not found; skipping social-preview.png. ",
          "Set CHROME_PATH to build it.")
  quit(save = "no")
}

url <- paste0("file:///", sub("^/", "", card))
status <- system2(chrome, c(
  "--headless=new", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
  "--force-device-scale-factor=1", "--allow-file-access-from-files",
  "--window-size=1200,630", "--virtual-time-budget=8000",
  shQuote(paste0("--screenshot=", out)), shQuote(url)
), stdout = FALSE, stderr = FALSE)

if (status == 0 && file.exists(out)) {
  message("[social card] wrote ", out)
} else {
  message("WARNING: [social card] Chrome failed (status ", status,
          "); social-preview.png not created.")
}
