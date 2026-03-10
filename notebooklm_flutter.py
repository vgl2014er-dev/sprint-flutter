from playwright.sync_api import sync_playwright
import time
import random

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()
        
        url = "https://notebooklm.google.com/notebook/dfb7db82-9cc7-4e43-8167-5966e5959c91"
        print(f"Navigating to {url}...")
        page.goto(url)
        
        # Wait for the textarea to be visible
        xpath = "//textarea[@placeholder='Text eingeben…']"
        print(f"Waiting for textarea: {xpath}")
        
        try:
            page.wait_for_selector(xpath, timeout=60000)
            
            questions = [
                "What are the benefits of using Flutter for cross-platform development?",
                "How does the Flutter engine work?",
                "What is the best state management solution for a large Flutter app?",
                "How do I optimize Flutter app performance?"
            ]
            question = random.choice(questions)
            print(f"Typing question: {question}")
            
            page.fill(xpath, question)
            page.press(xpath, "Enter")
            
            print("Waiting for response...")
            # We need to wait for the response to start and then finish.
            # Usually, NotebookLM shows a 'stop' button or similar while generating.
            # For simplicity, we'll wait for a few seconds and then try to capture the last message.
            time.sleep(20)
            
            # Fetch the last response. This is more complex as the structure depends on the page.
            # I'll take a screenshot to help the user see the result.
            page.screenshot(path="notebook_answer.png")
            print("Answer captured in notebook_answer.png")
            
        except Exception as e:
            print(f"An error occurred: {e}")
            page.screenshot(path="notebook_error.png")
            print("Error screenshot saved to notebook_error.png")
        
        browser.close()

if __name__ == "__main__":
    main()
