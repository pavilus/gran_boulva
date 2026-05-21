from pathlib import Path
from playwright.sync_api import sync_playwright


ROOT = Path(__file__).resolve().parent
DOCS = [
    ("one-page-business-plan.html", "gran-boulva-one-page-business-plan.pdf"),
    ("complete-business-plan.html", "gran-boulva-complete-business-plan.pdf"),
    ("investor-pitch-deck.html", "gran-boulva-investor-pitch-deck.pdf"),
]


def export_pdf(page, source: str, target: str) -> None:
    page.goto((ROOT / source).as_uri(), wait_until="networkidle")
    page.pdf(
        path=str(ROOT / target),
        format="Letter",
        print_background=True,
        prefer_css_page_size=True,
        margin={"top": "0", "right": "0", "bottom": "0", "left": "0"},
    )


def main() -> None:
    chrome = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
    with sync_playwright() as p:
        launch_options = {}
        if chrome.exists():
            launch_options["executable_path"] = str(chrome)
        browser = p.chromium.launch(**launch_options)
        page = browser.new_page(viewport={"width": 1100, "height": 850})
        for source, target in DOCS:
            export_pdf(page, source, target)
            print(f"exported {target}")
        browser.close()


if __name__ == "__main__":
    main()
