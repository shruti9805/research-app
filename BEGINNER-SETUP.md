# Complete beginner setup — no prior knowledge assumed

If you've never used a terminal, GitHub, or Claude Code before, this guide walks through every detail.

---

## Part 0 — What you need on your computer

**Check these first, before installing anything.**

### 1. Operating system

Claude Code runs on:
- **macOS** version 10.15 or newer
- **Windows** 10 or newer (two options below)
- **Linux** (Ubuntu 20.04+ or Debian 10+)

**How to check on your machine:**
- **Mac:** Click the Apple logo (top left) → "About This Mac" → "System Version"
- **Windows:** Right-click "This PC" or "My Computer" → "Properties" → look for "Windows 10" or "Windows 11"
- **Linux:** Open a terminal and run `cat /etc/os-release` (you'll see Ubuntu or Debian version)

If you have Windows 10 or newer, you have two choices:

**Option A (easier if you've never used Linux):** Run Claude Code natively on Windows. Works fine. You need "Git for Windows" (a free tool), but the installer will tell you if you're missing it.

**Option B (slightly more complex):** Use WSL (Windows Subsystem for Linux). This is Windows running a Linux layer. Skip this unless you already know what it is.

### 2. Node.js

Claude Code needs Node.js version 18 or newer.

**How to check if you have it:**
Open a terminal and type:
```
node --version
```

Press Enter. You'll see either:
- A version number like `v18.5.0` (great, you're ready)
- A "command not found" error (you need to install it)

**How to install Node.js:**

Go to https://nodejs.org and click the big green button that says "Download the LTS version". LTS means "Long Term Support" — that's the stable one.

Follow the installer that downloads. It's next-next-finish like any Windows/Mac installer. When it's done, close and reopen your terminal, then run `node --version` again to confirm it worked.

### 3. A text editor

You need something to edit text files (not Word, just plain text).

Free options everyone has:
- **Mac:** TextEdit (already installed)
- **Windows:** Notepad (already installed)
- **Linux:** gedit or nano (already installed)

Free options that are nicer (optional):
- **Visual Studio Code** (https://code.visualstudio.com) — works on all systems. Download the installer and run it. It's designed for coding but works for plain text files too.

You don't have to download anything fancy; Notepad or TextEdit is fine for this project.

### 4. Git

Git is version control — it tracks changes to your code so you can see what changed, who changed it, and undo mistakes.

**Mac:** Install Xcode Command Line Tools. Open Terminal and run:
```
xcode-select --install
```

A window pops up. Click "Install". Done.

**Windows (if using native Windows):** Download from https://git-scm.com/download/win. Run the installer. Defaults are fine — just next-next-finish. (If you chose WSL above, Git comes with Linux.)

**Linux:** Already included.

**How to verify:** Open a terminal and run:
```
git --version
```

You should see a version number like `git version 2.34.1`.

---

## Part 1 — Opening a terminal

A terminal is where you type commands to tell your computer to do things. It looks scary but it's just a text interface.

**Mac:**
- Press Cmd+Space
- Type "terminal"
- Press Enter
- A black window opens with white text

**Windows:**
- Press Win+R (Windows key and R at the same time)
- Type `powershell`
- Press Enter
- A blue window opens

(If you installed Git for Windows, you can also use "Git Bash" instead — same commands, slightly different colors.)

**Linux:**
- Open the applications menu
- Search for "Terminal"
- Click it

You should now see a terminal window with a prompt (a line where you can type). It might look like:
```
$
```
or
```
username@computer:~$
```

That's your starting point.

---

## Part 2 — Understanding folders (directories)

When you type commands in a terminal, you're always "in" a folder. Think of it like standing in a specific drawer of a filing cabinet.

**Key commands:**

`pwd` — Print Working Directory. Shows you which folder you're in right now.

Type it and press Enter:
```
pwd
```

You'll see something like `/Users/yourname` (Mac/Linux) or `C:\Users\yourname` (Windows).

`ls` (Mac/Linux) or `dir` (Windows) — List. Shows you what files and folders are inside the current folder.

Type it and press Enter. You'll see a list of folders and files.

`cd foldername` — Change Directory. Moves you into a folder.

To go into a folder named "Documents", you type:
```
cd Documents
```

Then press Enter. Now you're inside Documents. Run `pwd` again to confirm.

`cd ..` — Go up one level (to the parent folder).

`mkdir foldername` — Make Directory. Creates a new folder.

```
mkdir research-app
```

This creates a folder named `research-app` inside whatever folder you're currently in.

**Making nested folders at once:**

Normally `mkdir` makes one folder. To make several at once (like `.claude/skills/mobile-app-builder/`), use the `-p` flag:

```
mkdir -p research-app/.claude/skills/mobile-app-builder research-app/samples
```

This creates:
- A folder named `research-app`
- Inside it, `.claude` folder
- Inside `.claude`, `skills` folder
- Inside `skills`, `mobile-app-builder` folder
- Also inside `research-app`, a `samples` folder

All in one command.

---

## Part 3 — Installing Claude Code

1. Open https://docs.anthropic.com/en/docs/claude-code/setup in your browser.

2. Scroll down to "Standard installation". You'll see a command like:
   ```
   npm install -g @anthropic-ai/claude-code
   ```
   
   But **don't use that** — it's the old way. The docs recommend the native installer instead.

3. Look for "Native binary installation (Beta)" section on that same page. Copy the command for your OS:
   - **Mac/Linux:** There's a one-line command
   - **Windows:** Similar

4. Go back to your terminal and paste the command. Press Enter. It will download and install Claude Code.

5. When it finishes, verify it worked by typing:
   ```
   claude --version
   ```

   You should see a version number like `claude/2.1.207` or similar.

**If you get an error:**

- On Mac/Linux: you might see "command not found". Try closing the terminal completely and opening a new one. Terminal caches the list of available commands.
- On Windows: make sure you installed Git for Windows first (see Part 0).

---

## Part 4 — Understanding GitHub (just the basics you need)

GitHub is a platform where code lives. Git is the tool that tracks changes; GitHub is the website where people store and share code.

**For this project, you don't need to upload anything to GitHub.** You're working locally on your own computer.

**But you do need Git,** because the staged build process uses it to make checkpoints. Each time a component is done, you "commit" the code — Git records a snapshot of what the code looked like at that moment. If something goes wrong later, you can go back to that snapshot.

**The commands you'll use:**

```
git init
```

This command is run once in your project folder. It sets up Git tracking for that folder.

```
git add .
```

This tells Git "remember all the changes I just made".

```
git commit -m "message here"
```

This tells Git "save this checkpoint with a description". The message is so you remember what you changed.

Example:
```
git commit -m "Component 1: Walking skeleton builds and runs"
```

**You don't need to learn all of Git.** The build process will tell you when to run these commands.

---

## Part 5 — Downloading and moving files

When you download files from your browser, they usually go to a "Downloads" folder.

**Mac:**
- Files go to `~/Downloads` (which is `/Users/yourname/Downloads`)

**Windows:**
- Files go to `C:\Users\yourname\Downloads`

**Linux:**
- Files go to `~/Downloads` (which is `/home/yourname/Downloads`)

**To move files using terminal:**

After you download the five .md files and the two samples from this conversation, you need to move them into your `research-app` folder.

Terminal way (if you're comfortable):
```
cd ~/Downloads
mv PRODUCT.md ~/research-app/
mv SKILL.md ~/research-app/.claude/skills/mobile-app-builder/
# ... repeat for each file
```

**Easier way (using your file browser):**

- Open your file browser (Finder on Mac, File Explorer on Windows)
- Navigate to Downloads
- Find the files you downloaded
- Create a folder called `research-app` somewhere on your computer (Desktop is fine)
- Create the subfolder structure inside it (`.claude/skills/mobile-app-builder/` and `samples/`)
- Copy the files into the right places

**Important:** The nested path `.claude/skills/mobile-app-builder/` matters. If SKILL.md isn't in that exact location, Claude Code won't find it.

---

## Part 6 — Editing text files

You'll need to edit `PRODUCT.md` to answer the blocking questions.

**Using Notepad/TextEdit:**

1. Right-click the file
2. "Open with" → Notepad (Windows) or TextEdit (Mac)
3. The file opens
4. Find the section you need to edit (use Ctrl+F to search for `§12`)
5. Type your answers
6. File → Save (or Ctrl+S)
7. Close

**Using Visual Studio Code (nicer but takes 2 minutes to learn):**

1. Open Visual Studio Code
2. File → Open Folder → Navigate to your `research-app` folder and select it
3. On the left sidebar, you see your files listed
4. Click on `PRODUCT.md`
5. It opens in the main area
6. Use Ctrl+F to find `§12`
7. Edit what you need
8. File → Save (or Ctrl+S)

---

## Part 7 — Complete step-by-step setup

Now you have all the background. Here's the actual sequence:

### Step 1: Install prerequisites
```
# Check you have Node.js 18+
node --version

# Check you have Git
git --version

# If either failed, go back to Part 0 and install
```

### Step 2: Create the project folder
Open terminal. Type:
```
mkdir -p research-app/.claude/skills/mobile-app-builder research-app/samples
cd research-app
git init
pwd
```

The last command (`pwd`) shows you where you are. You should see something like `/Users/yourname/research-app` or `C:\Users\yourname\research-app`.

### Step 3: Download the files
In your browser, download these five files from this conversation:
- SKILL.md
- PRODUCT.md
- ONDEVICE-OPTIONS.md
- KICKOFF.md
- README.md

They'll go to Downloads.

### Step 4: Move files into place

**Option A: Using your file browser (easier)**
- Open File Explorer (Windows) or Finder (Mac)
- Go to Downloads
- Find the five files you just downloaded
- Go to your research-app folder
- Drag SKILL.md into `.claude/skills/mobile-app-builder/`
- Drag the other four into the root of `research-app/`

**Option B: Using terminal**
```
cd ~/Downloads  # or C:\Users\yourname\Downloads on Windows
mv SKILL.md ~/research-app/.claude/skills/mobile-app-builder/
mv PRODUCT.md ~/research-app/
mv ONDEVICE-OPTIONS.md ~/research-app/
mv KICKOFF.md ~/research-app/
mv README.md ~/research-app/
```

(On Windows, use `move` instead of `mv`)

### Step 5: Copy the sample files
You have two files from the original upload:
- Student_Survey_Bilingual.docx
- Student_Questionnaire_BP_Pujari_1.pdf

Copy both into `research-app/samples/`.

### Step 6: Edit PRODUCT.md
Open `research-app/PRODUCT.md` in your text editor.

Search for `## 12. Open questions` (use Ctrl+F).

Find these questions and type your answers directly below them:
- Q2: How does a response tie to a person?
- Q7: Team, timeline, budget?
- Q9: Accuracy bar and review policy?
- Q13: Adobe Scan or in-app capture?
- Q14: Is collection finished or ongoing?

Rough answers are fine. Save the file when done.

### Step 7: Decide on §14.6
Still in PRODUCT.md, search for `14.6`.

This is the batch-metadata proposal. Read what it says. If you like it, change "Proposed" to "DECIDED". If not, delete the whole section.

Save the file.

### Step 8: Install Claude Code

Follow Part 3 above. Stop when you've verified `claude --version` works.

### Step 9: Start Claude Code

Open terminal and navigate to your research-app folder:
```
cd ~/research-app
```

(Replace `~` with your actual path if needed.)

Now type:
```
claude
```

Press Enter. Claude Code starts. You'll see messages and a prompt. It might ask you to log in — follow the instructions on screen.

### Step 10: Run the kickoff

Open `KICKOFF.md` in any text editor. Look for the section `## Kickoff prompt`.

Copy the entire code block under it (everything between the triple backticks). 

In the Claude Code terminal, paste it and press Enter. 

Claude will start reading your files and asking questions. Answer them. Then it will produce `PLAN.md`.

---

## Troubleshooting the most common mistakes

**"command not found: claude"**
- You installed Claude Code but the terminal doesn't know about it yet
- **Fix:** Close terminal completely and open a new one

**"SKILL.md not found"**
- Claude Code didn't pick up the skill
- The file is in the wrong folder
- **Fix:** Verify the full path is exactly `.claude/skills/mobile-app-builder/SKILL.md`

**"node: command not found"**
- Node.js isn't installed or the terminal is using an old cache
- **Fix:** Go back to Part 0 and install Node.js; then close and reopen terminal

**Files won't move in terminal**
- You're in the wrong folder
- The filename is slightly different (e.g., extra spaces or numbers)
- **Fix:** Use your file browser instead (Option A); it's more forgiving

**Can't find the § symbol**
- That's the "section" symbol, used in the docs
- **Fix:** When searching in your editor, search for "12. Open questions" instead

**Downloaded file has a number in it like PRODUCT (1).md**
- Your browser added the number because a file with that name already existed
- **Fix:** Rename it to remove the number before moving it

---

## You're ready to go

When you've completed Part 7 steps 1–9, you're all set. Step 10 starts the actual plan-building process, and Claude Code will guide you from there.

If something confuses you, ask Claude Code itself — it's good at explaining terminal commands and debugging setup issues.
