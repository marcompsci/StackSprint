# StackSprint: how the app helps people remember (research notes)

Last updated: November 19, 2026 (phases 81–120 added)

This document summarizes the research behind StackSprint's learning and engagement features, and where each idea lives in the app.

## 1. What makes information stick

| Finding | Evidence | In StackSprint |
|---|---|---|
| **Retrieval practice (the testing effect).** Recalling an answer beats rereading it. Rereading looks better after 5 minutes. Testing wins after 2 days and after 1 week. | Roediger & Karpicke (2006), *Psychological Science*. Classroom and lab meta-analyses put the effect around Hedges' g = 0.50 (Yan, Sana & Carvalho, 2024). | A **5-question quiz after every lesson** (`LessonQuizBuilder`). Correct answers earn XP. Missed ones show "Remember this" notes. |
| **Spacing.** Reviews spread over days beat cramming. | Spaced vs. massed practice: g ≈ 0.74 (same review). One study found an 8-day gap beat a 1-day gap on a test 5 weeks later. More spacing is not always better. | The quiz score sets the next review (SM-2). A score of 5/5 pushes the review out further. A score of 2/5 or lower brings the lesson back tomorrow. |
| **Forgetting curve / half-life.** Recall probability decays roughly as *p = 2^(−Δ/h)*. Δ is the time since practice and *h* is the memory's half-life, which grows with successful reviews. | Settles & Meeder (2016), "A Trainable Spaced Repetition Model for Language Learning", ACL. This is Duolingo's half-life regression model. | `MemoryModel` estimates each lesson's recall right now. **Stats → Memory** shows strong, holding and fading lessons. Reviews are timed for when recall nears 90%. |
| **Pretesting / generation.** Guessing before being taught improves later recall, even when the guess is wrong, as long as feedback follows right away. | Pretesting literature, reviewed in the same meta-analyses. Retrieval only works with feedback when learners can't yet recall the answer. | The **Quick guess** card appears before the explanation on a new lesson. It has no score and shows the answer immediately. |
| **Discrimination and interleaving.** Telling similar ideas apart improves transfer. | Interleaving and discrimination-learning studies (Dunlosky et al., 2013; meta-analysis of ten learning techniques, 2021). | Question 5 of every lesson quiz contrasts the lesson with its most similar neighbour. Practice has mixed-track rounds. |
| **Priority first.** Test the core meaning before the details. | Instructional design practice. Learners can't recall details of a concept they can't define. | Questions are ordered: what it means → name it → key detail → spot it in use → tell it apart. |

### How intensive government language programs work

The Defense Language Institute, which trains military and intelligence linguists, runs about 7 hours of class a day, 5 days a week. Courses last 35–64 weeks and add homework and self-study on top. Students:

- learn high-frequency phrases first
- memorize 20–80 new words a night
- record and transcribe speech
- go through multi-day immersion simulations
- are tested often against proficiency levels

The transferable lessons are:

- daily, active, effortful recall
- frequent low-stakes testing
- immediate feedback
- learning the most useful material first

StackSprint can't replicate full immersion. It applies those principles in minutes a day: a daily target, a quiz after every lesson, scheduled reviews, and priority-ordered questions.

## 2. What keeps learners coming back (Duolingo and others)

| Finding | Evidence | In StackSprint |
|---|---|---|
| Streaks build a habit through loss aversion. Early days matter most. | Duolingo: learners who reach a 7-day streak are 3.6× more likely to finish their course. A milestone celebration raised 7-day retention by 1.7%. | Streak, plus a **milestone banner** at 3, 7, 14, 30, 50, 100, 200 and 365 days on the session-complete screen. |
| Some slack helps. Duolingo allows up to two streak freezes. | Allowing two freezes increased daily active learners by 0.38% (Duolingo). | One freeze earned per 7 days of streak, up to 2. Freezes cover a missed day automatically. |
| Reminder wording loses its pull when repeated (the "novelty effect"). Duolingo's bandit algorithm demotes recently sent messages. | Duolingo's "Recovering Difference Softmax" bandit: +0.5% daily active users and +2% new-user retention (KDD 2020). | `ReminderCopy.pick` avoids the last few messages sent. |
| Timely, relevant reminders work better than generic ones. | Same research. Reminders are personalized to the learner's situation. | Reminders come **at the hour you usually study** (`StudyRoutine`). When lessons are due, the reminder says how many are fading that day. Otherwise it names your actual next lesson. |
| The end of a session is where people decide to come back. | Product practice across learning apps. | The **session-complete screen** shows XP earned, streak, today's target, when the lesson comes back, and what to remember. |

What StackSprint deliberately does not copy:

- Leagues against other people. The app has no server-side multiplayer, and it doesn't invent fake opponents.
- Hearts or lives that block learning.
- Anything that sells a streak back.

## 3. AI Skills track (subscription)

Anthropic's free courses teach people to work with AI by:

- deciding what to hand to AI
- describing tasks clearly
- judging what AI produces
- using it responsibly

Anthropic's public prompting guidance also covers:

- be clear and direct
- add context
- use examples
- structure with tags
- give a role
- ask for step-by-step thinking
- have it self-check

StackSprint's AI Skills track is **original, beginner-level content** on these general skills. It uses its own wording and structure:

- choosing the job
- clear instructions, context, examples and structure
- roles, step-by-step thinking and iterating
- hallucinations and checking answers
- privacy, bias, being open about AI use, safe use, and respecting creators

It doesn't reproduce course materials, and it doesn't claim affiliation with or endorsement by any AI company. The track has 16 lessons plus 8 "prompt makeover" exercises.

## 4. Professional Practice (one-time purchase)

There are 12 lessons on how working developers operate:

- commits, branches, pull requests and code review
- unit tests and CI
- debugging and readable code
- secrets, semantic versioning, accessibility and logging

## 5. Added in phases 81–100

| Finding | Evidence | In StackSprint |
|---|---|---|
| **Confidence checks.** Rating how sure you are shows what you only *think* you know. Mistakes made with high confidence are corrected especially well once feedback comes (the hypercorrection effect). | Butterfield & Metcalfe (2001), and later work reviewed by Metcalfe. | Each quiz answer asks **Sure / Guessing** (can be turned off). Correct guesses and confident mistakes bring the review sooner. |
| **Typed recall.** Producing an answer is harder than recognising it, and harder retrieval builds stronger memory. | Retrieval-practice literature (the same meta-analyses as above). | Optional **Type answers** mode for the "Name it" question, forgiving small typos on longer terms. |
| **Self-explanation.** Explaining in your own words improves understanding. | Bisra et al. (2018), 64 studies, about 6,000 learners: g ≈ 0.55. | **Explain it in your own words** box in every lesson, with a check of which key ideas you covered. |
| **Interleaving.** Mixing similar topics helps tell them apart. Moderate overall effect; it varies by material and can reverse for word lists. | Brunmair & Richter (2019): g ≈ 0.42. | **Mixed review** in Practice: weakest lessons first, never the same lesson twice in a row. It's an option, not the default. |
| **Spaced retest.** A second test a day or more later combines spacing and retrieval. | Same spacing research as above. | **Still remember…?** card on Learn for a lesson quizzed 1–3 days ago. |
| **Sleep and memory.** Sleep helps consolidate what you learned that day. | Diekelmann & Born (2010), *Nature Reviews Neuroscience*. | Opt-in **evening review** reminder at 9 pm, only on days lessons are due. |
| **Plans with a date.** A concrete plan makes follow-through more likely. | Implementation-intentions research. | **Study plan**: pick a track and a finish date, see lessons per day. |

Engagement additions: "You vs. last week" (compete with your past self, not strangers), track certificates (clearly labelled as in-app achievements), and a free sample lesson for each paid offer so people can try before they buy.

## 6. Added in phases 101–120

- **Placement check.** Learners who already know part of a track take a short "what it means" check. Only answers that are right *and* marked Sure count; those lessons are skipped by Continue but come back for a review in a few days, so prior knowledge is verified rather than assumed. They earn no XP.
- **Calibration.** Memory shows how often "Sure" answers are right, and lists lessons with mistakes the learner was sure about (the ones most worth revisiting).
- **Targeted practice.** A drill of the learner's weakest question type, and a full answer review after every quiz.
- **Two-minute review.** On days without practice, a 3-question review (due lessons first) keeps the habit alive with minimal effort. Also available from Siri and Shortcuts.
- **Focus timer.** 10, 15 or 25-minute sessions with a clear end, tracked on the device.
- **Glossary and notes export.** Every finished term, searchable, with memory strength, plus a Markdown export of the learner's own notes and explanations.
- **Next-day retest reminders.** The daily reminder names a lesson that's due for its retest.

## Sources

- Roediger & Karpicke (2006), Test-enhanced learning — https://pubmed.ncbi.nlm.nih.gov/16507066/
- Yan, Sana & Carvalho (2024), Retrieval and spacing effect sizes — https://pmc.ncbi.nlm.nih.gov/articles/PMC10950551
- A Meta-Analysis of Ten Learning Techniques (2021) — https://www.doi.org/10.3389/feduc.2021.581216
- Settles & Meeder (2016), A Trainable Spaced Repetition Model for Language Learning — https://preview.aclanthology.org/landing_page/P16-1174 · code: https://www.github.com/duolingo/halflife-regression
- Duolingo, How the streak builds habit — https://blog.duolingo.com/how-duolingo-streak-builds-habit
- Duolingo, The AI behind its reminders — https://blog.duolingo.com/hi-its-duo-the-ai-behind-the-meme/
- A Sleeping, Recovering Bandit Algorithm for Optimizing Recurring Notifications — https://paperswithcode.com/paper/a-sleeping-recovering-bandit-algorithm-for
- How U.S. military linguists learn languages fast (DLI) — https://storylearning.com/blog/how-us-military-linguists-learn-languages-fast
- AI Fluency course overview (eWeek) — https://www.eweek.com/news/anthropic-ai-fluency-course/
- Bisra et al. (2018), Inducing self-explanation: a meta-analysis — https://doi.org/10.1007/s10648-018-9434-x
- Self-explanation meta-analysis summary (BPS Research Digest) — https://www.bps.org.uk/research-digest/self-explanation-powerful-learning-technique-according-meta-analysis-64-studies
- Brunmair & Richter (2019), Similarity matters: a meta-analysis of interleaved learning — https://pubmed.ncbi.nlm.nih.gov/31556629/
- Hypercorrection of high-confidence errors (review) — https://pmc.ncbi.nlm.nih.gov/articles/PMC4084803
- Diekelmann & Born (2010), The memory function of sleep — https://www.doi.org/10.1038/NRN2762
- Claude prompting best practices — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/be-clear-and-direct
