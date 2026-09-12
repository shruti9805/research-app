# Setup for Claude Code Web (claude.ai/code)

You're using Claude Code in your browser. This guide is specifically for that.

---

## What you have

When you go to https://claude.ai/code, you get:
- A terminal (bash) where you can run commands
- A file editor for text files
- A file browser
- Everything sandboxed in the browser (files don't touch your computer's disk directly)

**No installation needed.** You're already ready to go.

---

## Step-by-step setup

### Step 1: Open Claude Code Web

Go to https://claude.ai/code in your browser.

You should see three panels:
- Left: File browser (initially empty)
- Middle: Main working area
- Right or below: Terminal

If you don't see a terminal, look for a button that says "Terminal" or similar and click it.

### Step 2: Create the folder structure

In the terminal at the bottom, type:

```
mkdir -p .claude/skills/mobile-app-builder samples
```

Press Enter.

Then verify it worked by typing:

```
ls -la
```

Press Enter. You should see two folders listed:
- `.claude/`
- `samples/`

### Step 3: Initialize Git

In the terminal, type:

```
git init
```

Press Enter. This sets up version control for the project.

### Step 4: Download the five .md files

In your **browser**, download these five files from this conversation:
1. README.md
2. SKILL.md
3. PRODUCT.md
4. ONDEVICE-OPTIONS.md
5. KICKOFF.md

They'll go to your computer's Downloads folder.

### Step 5: Upload the files to Claude Code Web

In Claude Code Web, look for an "Upload" button or right-click in the file browser on the left.

Upload the five files one at a time:
- SKILL.md → right-click `.claude/skills/mobile-app-builder/` folder → Upload here
- PRODUCT.md → Upload to the root folder
- ONDEVICE-OPTIONS.md → Upload to the root folder
- KICKOFF.md → Upload to the root folder
- README.md → Upload to the root folder

(If there's no upload button, you can also create the files manually — see **Step 5 Alternative** below.)

### Step 5 Alternative: Create files manually

If uploading doesn't work, create them manually:

1. In Claude Code Web, right-click the file browser → "New File"
2. Name it `SKILL.md`
3. A text editor opens
4. Open `SKILL.md` from this conversation in your browser, copy the entire content
5. Paste it into Claude Code Web's editor
6. Click "Save"
7. Repeat for the other four files

It's tedious but it works.

### Step 6: Upload the two sample files

Download these from the original Research App project context:
- Student_Survey_Bilingual.docx
- Student_Questionnaire_BP_Pujari_1.pdf

Upload both into the `samples/` folder in Claude Code Web.

(If upload doesn't work for .pdf and .docx, you might not be able to store them in Claude Code Web — but you can reference them from your file system when needed, or work around it by asking Claude to read them if you can paste their contents.)

### Step 7: Verify the structure

In Claude Code Web's terminal, type:

```
find . -type f -name "*.md" | head -10
```

Press Enter. You should see your five .md files listed.

Also check:

```
ls -la .claude/skills/mobile-app-builder/
```

You should see `SKILL.md` listed there.

### Step 8: Edit PRODUCT.md

In Claude Code Web's file browser (left panel), click `PRODUCT.md`.

It opens in the editor. Use Ctrl+F to search for `## 12. Open questions`.

Scroll down and find the five blocking questions:
- Q2
- Q7
- Q9
- Q13
- Q14

Type your answers directly below each question. Rough answers are fine.

Also search for `14.6` and decide whether to keep it (change "Proposed" to "DECIDED") or delete it.

Save the file when done (Ctrl+S or look for a Save button).

### Step 9: Commit your answers

In the terminal, type:

```
git add PRODUCT.md
git commit -m "Answer blocking questions"
```

Press Enter. This creates a checkpoint of your answers.

### Step 10: Start the kickoff

In this chat window (not in Claude Code Web — come back here):

Open `KICKOFF.md` and find the kickoff prompt code block.

Copy the entire prompt.

Come back to Claude Code Web's terminal and paste it:

```
claude
```

Wait — Claude Code Web might not have a `claude` command. Instead, just paste the prompt as a message back in this chat window. Continue the conversation here, not in Claude Code Web's terminal.

---

## The key difference: browser vs desktop

| | Claude Code Desktop | Claude Code Web (https://claude.ai/code) |
|---|---|---|
| Terminal access | Yes | Yes |
| File editing | Yes | Yes |
| Folder creation | Yes | Yes |
| Git | Yes | Yes |
| Upload/download files | Via your computer's file system | Upload button in browser, download via browser download |
| Can run the project here | Yes, fully | Partially — no desktop compilation, but works for planning |

For this project, Claude Code Web is sufficient. You're building a mobile app, but Stage 1 is just planning — the actual coding happens in Stage 2+, and you can switch to Desktop later if needed.

---

## Final folder structure (in Claude Code Web)

When you're done, your file browser should show:

```
.
├── .claude/
│   └── skills/
│       └── mobile-app-builder/
│           └── SKILL.md
├── samples/
│   ├── Student_Survey_Bilingual.docx
│   └── Student_Questionnaire_BP_Pujari_1.pdf
├── README.md
├── PRODUCT.md
├── ONDEVICE-OPTIONS.md
├── KICKOFF.md
└── .git/
```

---

## Running the kickoff

Once you've uploaded all files and edited PRODUCT.md:

1. Come back to **this chat window** (not Claude Code Web)
2. Say: "I've set up the files. Here's my kickoff prompt:" 
3. Copy the prompt from KICKOFF.md
4. Paste it
5. I'll ask any missing questions and produce PLAN.md
6. You'll review the plan here in chat
7. Once you approve, I'll guide you on the next steps

The planning phase happens here in the chat; the building phase uses Claude Code Web's terminal and editor.

---

## Troubleshooting for Claude Code Web

**"Upload button not found"**
- Use the manual file creation method (Step 5 Alternative)
- Create files one at a time by copying and pasting content

**"Can't upload .docx or .pdf"**
- Claude Code Web might have restrictions on binary files
- Workaround: you can still reference them — I can read them and you can tell me what they contain if needed

**"Terminal command not found"**
- Claude Code Web is a sandbox; it has bash, git, and basic tools
- If a command fails, tell me — there might be a different way in this environment

**"Changes not saving"**
- Look for a "Save" button or try Ctrl+S
- Check the file appears in the file browser on the left

---

## Next step

Once you've completed steps 1–9 above, come back to this chat and paste the kickoff prompt. We'll start Stage 1 here.
