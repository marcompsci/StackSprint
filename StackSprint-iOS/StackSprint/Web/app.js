const cards = [
  {
    id: "html",
    term: "HTML",
    category: "frontend",
    categoryLabel: "Front-end foundation",
    clue: "It gives every webpage its structure.",
    definition: "HTML is the structure and content of a page — headings, paragraphs, buttons, images, and links.",
    example: "A <b>button</b> or a page heading starts as HTML.",
    code: "<button>Save</button>",
    readAloud: "Read it like this: <b>opening button tag, Save, closing button tag.</b>"
  },
  {
    id: "css",
    term: "CSS",
    category: "frontend",
    categoryLabel: "Front-end foundation",
    clue: "It makes the page look and feel like itself.",
    definition: "CSS controls the visual style: colors, spacing, layout, fonts, and tiny animations.",
    example: "Making a button bright blue with soft corners is <b>CSS</b>.",
    code: "button { color: blue; }",
    readAloud: "Read it like this: <b>button, open brace, color blue, close brace.</b>"
  },
  {
    id: "javascript",
    term: "JavaScript",
    category: "frontend",
    categoryLabel: "Front-end behavior",
    clue: "It reacts when someone clicks, types, or scrolls.",
    definition: "JavaScript is code that makes a page respond and change when people interact with it.",
    example: "A menu opening after a click is <b>JavaScript</b> at work.",
    code: "openMenu();",
    readAloud: "Read it like this: <b>open menu, open parenthesis, close parenthesis.</b>"
  },
  {
    id: "dom",
    term: "DOM",
    category: "frontend",
    categoryLabel: "Front-end behavior",
    clue: "A live map of the page in the browser.",
    definition: "The DOM is how a browser represents page elements so JavaScript can read or change them.",
    example: "Changing “Hello” to “Welcome back” updates the <b>DOM</b>.",
    code: "document.querySelector(\"h1\");",
    readAloud: "Read it like this: <b>document dot query selector, h one.</b>"
  },
  {
    id: "frontend",
    term: "Front-end",
    category: "frontend",
    categoryLabel: "Front-end role",
    clue: "The part of an app people can actually see and use.",
    definition: "Front-end development builds the screens, interactions, and experiences that run in a browser.",
    example: "The login form, product photos, and checkout button are <b>front-end</b>.",
    code: "showLoginForm();",
    readAloud: "Read it like this: <b>show login form, open parenthesis, close parenthesis.</b>"
  },
  {
    id: "server",
    term: "Server",
    category: "backend",
    categoryLabel: "Back-end engine",
    clue: "It listens for requests and sends useful answers back.",
    definition: "A server is a computer or cloud service that runs back-end code for an app.",
    example: "After you log in, a <b>server</b> can check whether your account exists.",
    code: "app.get(\"/profile\", getProfile);",
    readAloud: "Read it like this: <b>app dot get, profile, get profile.</b>"
  },
  {
    id: "database",
    term: "Database",
    category: "backend",
    categoryLabel: "Back-end engine",
    clue: "A tidy place for an app to remember things.",
    definition: "A database stores organized information such as user accounts, posts, orders, or scores.",
    example: "Your saved profile details can live in a <b>database</b>.",
    code: "SELECT * FROM users;",
    readAloud: "Read it like this: <b>select star from users.</b>"
  },
  {
    id: "api",
    term: "API",
    category: "backend",
    categoryLabel: "Back-end connection",
    clue: "A clear doorway for software to ask for information.",
    definition: "An API is an agreed way for different parts of software to request and share information.",
    example: "The front-end can ask an <b>API</b> for a list of your saved tasks.",
    code: "fetch(\"/api/tasks\");",
    readAloud: "Read it like this: <b>fetch, API tasks.</b>"
  },
  {
    id: "authentication",
    term: "Authentication",
    category: "backend",
    categoryLabel: "Back-end protection",
    clue: "The check that answers: “Are you really you?”",
    definition: "Authentication verifies someone’s identity before an app lets them access protected information.",
    example: "Checking a password securely happens on the <b>back-end</b>.",
    code: "if (isValid) { logIn(); }",
    readAloud: "Read it like this: <b>if is valid, log in.</b>"
  },
  {
    id: "backend",
    term: "Back-end",
    category: "backend",
    categoryLabel: "Back-end role",
    clue: "The behind-the-scenes logic that powers the screen.",
    definition: "Back-end development handles data, business rules, security, and requests away from the visible page.",
    example: "Calculating a total and saving an order are <b>back-end</b> jobs.",
    code: "saveOrder(order);",
    readAloud: "Read it like this: <b>save order, order.</b>"
  },
  {
    id: "request-response",
    term: "Request + response",
    category: "fullstack",
    categoryLabel: "The connection",
    clue: "One part asks. Another part answers.",
    definition: "A request asks for something; a response is the information or result sent back.",
    example: "Your browser requests your profile, and the server <b>responds</b> with it.",
    code: "fetch(\"/api/profile\");",
    readAloud: "Read it like this: <b>fetch, API profile.</b>"
  },
  {
    id: "fullstack",
    term: "Full-stack",
    category: "fullstack",
    categoryLabel: "Across the stack",
    clue: "It joins the visible experience and the system behind it.",
    definition: "Full-stack work spans both front-end and back-end, helping a feature travel from screen to data and back.",
    example: "A full-stack developer might build a form <b>and</b> the API that saves it.",
    code: "sendFormToApi();",
    readAloud: "Read it like this: <b>send form to API.</b>"
  }
];

const quizQuestions = [
  // Round 1: Front-end foundations
  {
    question: "Which part of a web app do people see, tap, and type into?",
    choices: ["The database", "The front-end", "The server room", "Authentication"],
    answer: 1,
    explanation: "Exactly — the front-end is the visible, interactive experience."
  },
  {
    question: "Which language gives a webpage its structure, such as headings, paragraphs, links, and buttons?",
    choices: ["CSS", "JavaScript", "HTML", "SQL"],
    answer: 2,
    explanation: "HTML provides the meaningful building blocks and content of a webpage."
  },
  {
    question: "A page already has a button, but it needs a blue background, rounded corners, and more space around it. What should you use?",
    choices: ["CSS", "HTML", "A database", "Authentication"],
    answer: 0,
    explanation: "CSS controls how page elements look and are arranged: color, spacing, typography, and layout."
  },
  {
    question: "Which language is a good fit for opening a menu after someone clicks its icon?",
    choices: ["HTML", "CSS only", "A database query", "JavaScript"],
    answer: 3,
    explanation: "JavaScript adds behavior, including responding to clicks, typing, scrolling, and other events."
  },
  {
    question: "In the browser, what is the DOM?",
    choices: ["A cloud service for storing files", "A CSS color palette", "A live representation of page elements JavaScript can read or change", "A kind of database"],
    answer: 2,
    explanation: "The DOM is the browser’s live map of the page, so JavaScript can find, update, add, or remove elements."
  },

  // Round 2: Back-end foundations
  {
    question: "Where should an app safely check a password and load private account data?",
    choices: ["On the back-end", "In a CSS file", "In a browser tab title", "Inside an image"],
    answer: 0,
    explanation: "Sensitive checks and data work belong on the back-end, away from code every browser visitor can inspect."
  },
  {
    question: "What is a server’s main job in a typical web app?",
    choices: ["Paint every button blue", "Replace HTML", "Listen for requests, run back-end logic, and send responses", "Store only fonts"],
    answer: 2,
    explanation: "A server receives requests, does useful work such as checking rules or data, and returns a response."
  },
  {
    question: "Which item is a good fit for a database?",
    choices: ["A visitor’s saved task list", "The color of one heading while it is loading", "A browser’s Back button", "A CSS media query"],
    answer: 0,
    explanation: "Databases store organized information an app needs to remember, such as accounts, tasks, posts, or orders."
  },
  {
    question: "What does an API give different parts of software?",
    choices: ["A replacement for all HTML", "A shared, agreed way to request and exchange data", "A way to make passwords visible", "A permanent screen layout"],
    answer: 1,
    explanation: "An API is a clear contract for how one part of software can ask another part for information or an action."
  },
  {
    question: "What question does authentication answer?",
    choices: ["“What color should this button be?”", "“Which database is fastest?”", "“How wide is this screen?”", "“Are you really who you say you are?”"],
    answer: 3,
    explanation: "Authentication verifies identity, such as when an app checks sign-in credentials."
  },

  // Round 3: Full-stack flow
  {
    question: "A browser sends “please give me my saved tasks” to an API. That outgoing message is a…",
    choices: ["Response", "Request", "Database", "Style rule"],
    answer: 1,
    explanation: "A request asks for something. The API or server then sends a response with a result, data, or an error."
  },
  {
    question: "A developer builds a checkout screen, an API route to receive the order, and database code to save it. What kind of work is this?",
    choices: ["Only front-end", "Only back-end", "Full-stack", "Only graphic design"],
    answer: 2,
    explanation: "Full-stack work spans the visible experience and the systems behind it, connecting a feature end to end."
  },
  {
    question: "Which sequence best describes saving a new task from a web page?",
    choices: ["Database → browser → CSS → response", "Browser → database → HTML → server", "Browser sends a request → server validates it → database saves it → server sends a response", "CSS sends a request → DOM saves it → browser restarts"],
    answer: 2,
    explanation: "A common full-stack flow starts in the browser, travels through a server to data storage, then returns a result."
  },
  {
    question: "A person submits a new comment. Which HTTP-style action most closely matches creating that new item?",
    choices: ["GET", "POST", "DELETE", "CSS"],
    answer: 1,
    explanation: "POST is commonly used when sending data to create a new resource, such as a comment or account."
  },
  {
    question: "After someone signs in, an app checks whether they may edit a team’s billing details. What is that permission check called?",
    choices: ["HTML", "Authorization", "Responsive design", "A DOM event"],
    answer: 1,
    explanation: "Authentication establishes who someone is; authorization determines what that signed-in person is allowed to do."
  },

  // Round 4: Practical quality
  {
    question: "A layout looks great on a laptop but its cards overflow on a phone. What is the best next step?",
    choices: ["Add responsive CSS for smaller screens", "Move the cards into a database", "Turn off HTML", "Store the phone in a server"],
    answer: 0,
    explanation: "Responsive CSS, often with flexible layouts or media queries, lets an interface adapt to different screen sizes."
  },
  {
    question: "Which choice makes a sign-up form more accessible to people using a screen reader?",
    choices: ["Use placeholder text instead of labels", "Make all text tiny", "Use only color to explain errors", "Give every input a clear visible label"],
    answer: 3,
    explanation: "Clear labels help everyone understand each field and give assistive technology a reliable name for it."
  },
  {
    question: "A custom clickable card should also work for someone navigating with a keyboard. What is the strongest starting choice?",
    choices: ["Use a plain div and only mouse clicks", "Make it a semantic button when it performs an action", "Hide its focus outline", "Require a touch screen"],
    answer: 1,
    explanation: "A real button brings helpful keyboard behavior and accessibility information by default."
  },
  {
    question: "Your task list fails to load. What is a useful first debugging move?",
    choices: ["Change every color in the app", "Delete the database immediately", "Check the browser console and Network panel for errors or failed requests", "Ignore the issue and refresh forever"],
    answer: 2,
    explanation: "The console and Network panel can reveal JavaScript errors, failed API calls, response details, and other useful clues."
  },
  {
    question: "An app builds a database query from untrusted text someone typed. Which approach is safer?",
    choices: ["Use parameterized queries and validate input", "Paste the text directly into the query", "Trust every input because it came from a form", "Put the query in CSS"],
    answer: 0,
    explanation: "Parameterized queries keep data separate from query instructions, helping protect against injection attacks."
  },

  // Round 5: AI-assisted web development
  {
    question: "Which prompt gives an AI agent the clearest request for a phone-friendly profile card?",
    choices: ["“Make it better.”", "“Use CSS to make the profile card responsive below 600px, stack its content, and keep text readable.”", "“Use the database to fix the screen.”", "“Remove the card on phones.”"],
    answer: 1,
    explanation: "A strong prompt names the tool, the goal, the context, and clear success criteria."
  },
  {
    question: "Which prompt best asks an AI agent for an accessible sign-up form?",
    choices: ["“Make a cool form.”", "“Use only placeholders so the form is cleaner.”", "“Build semantic HTML with visible labels, an email field, and clear error feedback.”", "“Hide every error message.”"],
    answer: 2,
    explanation: "Naming semantic HTML, labels, fields, and feedback gives the agent useful accessibility requirements."
  },
  {
    question: "An AI agent suggests placing a private API key in front-end JavaScript. What is the right response?",
    choices: ["Ask it to move the secret to protected server-side configuration", "Leave it there because the code is minified", "Put the key in a CSS comment", "Show the key in the login form"],
    answer: 0,
    explanation: "Anything sent to the browser can be inspected. Private keys and other secrets must stay on the server."
  },
  {
    question: "Which prompt gives an AI agent the clearest API task?",
    choices: ["“Make an API.”", "“Do something with tasks.”", "“Create a POST /api/tasks endpoint that validates a title, saves the task, returns JSON on success, and explains validation errors.”", "“Make the request invisible.”"],
    answer: 2,
    explanation: "A useful implementation prompt specifies the route, input, behavior, successful response, and failure behavior."
  },
  {
    question: "An AI-generated task list is blank. Which follow-up prompt is most useful for debugging?",
    choices: ["“Try harder.”", "“Check the browser console and Network request for the tasks API; explain any error, status code, and fix.”", "“Change the background color.”", "“Delete all task code.”"],
    answer: 1,
    explanation: "A focused debugging prompt gives the agent evidence to inspect and asks for an explanation plus a safe next step."
  }
];

const cyberTerms = [
  {
    id: "phishing",
    term: "Phishing",
    clue: "A fake message or site that tries to trick you.",
    definition: "Phishing uses believable messages, links, or websites to steal information such as passwords or payment details."
  },
  {
    id: "malware",
    term: "Malware",
    clue: "Software made to harm, spy, or break in.",
    definition: "Malware is malicious software designed to disrupt a device, steal data, or gain unwanted access."
  },
  {
    id: "ransomware",
    term: "Ransomware",
    clue: "Malware that locks data and demands money.",
    definition: "Ransomware can encrypt or block access to files, then demand payment for their return."
  },
  {
    id: "vulnerability",
    term: "Vulnerability",
    clue: "A weakness someone could take advantage of.",
    definition: "A vulnerability is a flaw in software, settings, or a process that could be exploited."
  },
  {
    id: "patch",
    term: "Patch / update",
    clue: "A repair that strengthens software.",
    definition: "A patch or update changes software to fix known problems, including security vulnerabilities."
  },
  {
    id: "mfa",
    term: "MFA",
    clue: "More than one way to prove it is you.",
    definition: "Multi-factor authentication asks for an extra sign-in factor, such as an authenticator code, in addition to a password."
  },
  {
    id: "authentication",
    term: "Authentication",
    clue: "The identity check at sign-in.",
    definition: "Authentication verifies who someone is before an account or system lets them in."
  },
  {
    id: "authorization",
    term: "Authorization",
    clue: "The permission check after sign-in.",
    definition: "Authorization decides what an authenticated person is allowed to view, change, or use."
  },
  {
    id: "least-privilege",
    term: "Least privilege",
    clue: "Only the access needed for the job.",
    definition: "Least privilege gives a person or system the minimum permissions needed, limiting the impact of mistakes or misuse."
  },
  {
    id: "encryption",
    term: "Encryption",
    clue: "Turning data into protected unreadable form.",
    definition: "Encryption transforms readable data into protected data that should only be understandable with the right key."
  },
  {
    id: "backups",
    term: "Backups",
    clue: "A separate copy for recovery.",
    definition: "Backups are copies of important data kept so it can be restored after loss, damage, or a ransomware incident."
  },
  {
    id: "sql-injection",
    term: "SQL injection",
    clue: "When unsafe input can change a database request.",
    definition: "SQL injection is a risk when untrusted input is treated as database-query instructions; parameterized queries help keep data separate from commands."
  }
];

const cyberQuizQuestions = [
  {
    question: "What is phishing designed to do?",
    choices: ["Make a device run faster", "Trick someone into sharing information or taking an unsafe action", "Create a backup", "Encrypt a trusted file for storage"],
    answer: 1,
    explanation: "Phishing relies on deception — often a convincing message, link, or login page — to steal information or prompt an unsafe action."
  },
  {
    question: "An unexpected email says your account will close today and asks you to sign in through its link. What is the safest first move?",
    choices: ["Use the link quickly", "Reply with your password", "Open the service through a known app or typed address and check there", "Forward the email to everyone"],
    answer: 2,
    explanation: "Avoid using a surprising link. Reach the service through a trusted route and check whether the alert is real."
  },
  {
    question: "Which description best fits malware?",
    choices: ["A browser bookmark", "Software designed to harm, spy on, or gain unwanted access", "A routine software update", "A method for making a password longer"],
    answer: 1,
    explanation: "Malware is malicious software. It can disrupt devices, steal information, or enable unwanted access."
  },
  {
    question: "What is ransomware known for?",
    choices: ["Improving Wi-Fi speed", "Locking or encrypting data and demanding payment", "Checking permissions after sign-in", "Creating a new user account"],
    answer: 1,
    explanation: "Ransomware commonly blocks access to data, then demands payment. Prepared backups can make recovery possible."
  },
  {
    question: "What is a vulnerability?",
    choices: ["A strength in an app", "A weakness in software, settings, or a process that could be exploited", "A type of password manager", "A backup copy of a database"],
    answer: 1,
    explanation: "A vulnerability is a weakness that could be used to compromise a system, account, or data."
  },
  {
    question: "Why do software patches and updates matter?",
    choices: ["They only change an app’s icon", "They can fix known bugs and security vulnerabilities", "They remove every password", "They guarantee no future risk"],
    answer: 1,
    explanation: "Updates often repair known issues, including security flaws. They reduce risk, though no single step eliminates all risk."
  },
  {
    question: "What does MFA add to a sign-in?",
    choices: ["A second or additional proof of identity", "A second username only", "A public password", "A way to skip authentication"],
    answer: 0,
    explanation: "MFA asks for more than one factor, such as a password plus an authenticator approval or security key."
  },
  {
    question: "A person enters a password and then approves a code in an authenticator app. What are they using?",
    choices: ["Authorization", "A backup", "MFA", "SQL injection"],
    answer: 2,
    explanation: "A password plus an authenticator approval is a common multi-factor authentication flow."
  },
  {
    question: "Authentication answers which question?",
    choices: ["What color should the page be?", "Who are you?", "Which files can you edit?", "How much storage is left?"],
    answer: 1,
    explanation: "Authentication verifies identity — for example, confirming that a sign-in belongs to the account holder."
  },
  {
    question: "Authorization answers which question?",
    choices: ["Are you really this account holder?", "What are you allowed to access or change?", "Is the password long enough?", "Has the device installed an update?"],
    answer: 1,
    explanation: "Authorization comes after identity is established and determines what that person is permitted to do."
  },
  {
    question: "A teammate can view a report but cannot edit it. Which concept is controlling that difference?",
    choices: ["Encryption", "Authorization", "Malware", "A phishing link"],
    answer: 1,
    explanation: "Authorization controls permissions, such as whether a signed-in person may view, edit, or administer something."
  },
  {
    question: "What does least privilege mean?",
    choices: ["Everyone gets administrator access", "People receive only the access needed for their work", "Passwords should be shared with a team", "Every account should have the same role"],
    answer: 1,
    explanation: "Least privilege limits access to what is needed, reducing the impact of mistakes, compromised accounts, or misuse."
  },
  {
    question: "A new contractor only needs to read one project folder. Which permission choice best follows least privilege?",
    choices: ["Give full administrator access", "Give access to every company folder", "Give read-only access to that project folder", "Share another employee’s account"],
    answer: 2,
    explanation: "The narrow, read-only permission meets the need without granting unrelated access."
  },
  {
    question: "What does encryption do to data?",
    choices: ["Deletes it permanently", "Turns readable data into protected data that needs the right key to read", "Makes every account public", "Removes the need for access controls"],
    answer: 1,
    explanation: "Encryption protects confidentiality by transforming readable data into a protected form that requires the appropriate key."
  },
  {
    question: "Which statement about encryption is most accurate?",
    choices: ["It replaces passwords, permissions, and updates", "It is one protection that works alongside other security practices", "It makes phishing impossible", "It is only useful for photos"],
    answer: 1,
    explanation: "Encryption is valuable, but security works in layers — it complements strong sign-ins, permissions, updates, and careful habits."
  },
  {
    question: "Why are backups important in a ransomware situation?",
    choices: ["They can provide a separate copy for recovery", "They make a suspicious link safe", "They automatically identify every scam", "They turn off MFA"],
    answer: 0,
    explanation: "Separate, usable backups can help restore data after an incident instead of relying on the affected copy."
  },
  {
    question: "Which is the best description of a useful backup?",
    choices: ["The only copy of a file on the same device", "A separate copy that can be restored when needed", "A password written in a chat", "A file that everyone can change"],
    answer: 1,
    explanation: "A backup should be a separate recoverable copy, and it is wise to check that restoration actually works."
  },
  {
    question: "What creates the risk of SQL injection?",
    choices: ["Treating untrusted input as part of a database command", "Using a strong passphrase", "Turning on MFA", "Keeping software updated"],
    answer: 0,
    explanation: "SQL injection can happen when input is interpreted as query instructions instead of handled purely as data."
  },
  {
    question: "Which approach helps reduce SQL injection risk?",
    choices: ["Build a query by pasting user input directly into it", "Use parameterized queries and validate input", "Hide the query in a CSS file", "Trust input because it came from a form"],
    answer: 1,
    explanation: "Parameterized queries keep data separate from query instructions, while validation limits unexpected input."
  },
  {
    question: "You receive a chat message from a coworker asking for an urgent gift-card purchase. What is the safest next step?",
    choices: ["Act immediately because it sounds urgent", "Verify the request through a known, separate channel", "Send your account password first", "Post the request publicly"],
    answer: 1,
    explanation: "Urgency is a common social-engineering tactic. Verify unusual requests using a trusted way to reach the person."
  },
  {
    question: "An app alerts you to a sign-in you do not recognize. What is a sensible immediate response?",
    choices: ["Ignore it if the app still works", "Change the password, review active sessions, and report it through the service", "Share the alert online with your password", "Install unrelated browser extensions"],
    answer: 1,
    explanation: "Treat unexpected sign-in alerts seriously: secure the account, remove unknown sessions, and use the service’s official support path if needed."
  },
  {
    question: "Which password habit is strongest?",
    choices: ["Reuse one memorable password everywhere", "Use long, unique passwords stored in a reputable password manager", "Share a password in a group chat", "Use a short word plus your birth year"],
    answer: 1,
    explanation: "Unique, long passwords limit damage from one compromised site. A password manager makes them practical to use."
  },
  {
    question: "What is the main benefit of using different passwords for different accounts?",
    choices: ["It makes phishing messages more believable", "One stolen password cannot unlock every account", "It removes the need for MFA", "It turns a vulnerability into a patch"],
    answer: 1,
    explanation: "Unique passwords contain the fallout if one service experiences a breach or a password is exposed."
  },
  {
    question: "Someone sends you an unexpected file and says, “Enable editing right away.” What is the safer choice?",
    choices: ["Enable it without checking", "Open it on every device", "Verify the sender and purpose before opening or enabling anything", "Forward it to your contacts"],
    answer: 2,
    explanation: "Unexpected files and unusual instructions deserve a pause. Verify independently before opening or enabling content."
  },
  {
    question: "Which response best combines authentication, authorization, and least privilege?",
    choices: ["Verify a person’s identity, then give only the permissions needed for their role", "Let anyone edit everything after entering an email", "Use the same administrator account for the whole team", "Skip sign-in if the person knows the project name"],
    answer: 0,
    explanation: "A safer system confirms identity, checks the role, and grants only the minimum access that role needs."
  }
];

const gameCheckpoint = (phase, prompt, correct, explanation, distractors = []) => ({ phase, prompt, correct, explanation, distractors });

const checkpointDistractors = {
  Plan: [
    "Skip the goal and make the first idea look final.",
    "Add every feature you can think of before choosing a focus.",
    "Copy a random screen without deciding who it is for."
  ],
  Sketch: [
    "Polish tiny visual details before deciding the screen order.",
    "Fill the screen with several competing actions.",
    "Start coding every possible feature at once."
  ],
  Build: [
    "Hide the main action behind extra decoration.",
    "Make the first version as complex as the final dream version.",
    "Change the rules whenever a player makes a choice."
  ],
  Test: [
    "Call it finished before another person tries it.",
    "Only ask whether the colors look nice.",
    "Keep feedback private and never change the next version."
  ]
};

function createGameProject(project, projectIndex) {
  return {
    ...project,
    steps: project.steps.map((step, stepIndex) => {
      const options = [step.correct, ...(step.distractors.length ? step.distractors : checkpointDistractors[step.phase])].slice(0, 4);
      const correct = options.shift();
      const answer = (projectIndex + stepIndex * 2) % 4;
      options.splice(answer, 0, correct);
      return { ...step, choices: options, answer };
    })
  };
}

const designGameProjects = [
  createGameProject({
    id: "palette-pop", emoji: "🎨", level: "Warm-up", title: "Palette Pop", skills: "color · contrast · mood",
    brief: "A tiny arcade café needs a three-color look that feels fizzy and friendly. Build a color mission that lets a player make one bright choice without losing readability.",
    outcome: "A mood card with three swatches, one primary action, and a score cue.",
    steps: [
      gameCheckpoint("Plan", "Before choosing colors for Palette Pop, what gives the game a clear visual direction?", "Pick a three-color palette and name the feeling it should create.", "A small palette plus a mood gives every later choice a reason."),
      gameCheckpoint("Sketch", "Which first screen best tests the Palette Pop idea?", "One card with a color choice, a clear primary button, and a tiny score cue.", "A focused screen makes the interaction and hierarchy easy to judge."),
      gameCheckpoint("Test", "What is the most useful first playtest question?", "Can a new player spot the action and read the score in a single glance?", "This checks contrast and hierarchy instead of relying on personal taste.")
    ]
  }, 0),
  createGameProject({
    id: "button-quest", emoji: "🔘", level: "Warm-up", title: "Button Quest", skills: "affordance · states · feedback",
    brief: "Design a treasure-hunt button that invites a tap, reacts with personality, and stays obvious in every state. The only prize is a satisfying interaction.",
    outcome: "A button state sheet for default, hover/focus, pressed, and success.",
    steps: [
      gameCheckpoint("Plan", "What should Button Quest define before styling the treasure button?", "The single action the player should understand and the feedback after it happens.", "A button is a promise: clarify the action and its result before decorating it."),
      gameCheckpoint("Sketch", "Which set of states belongs in a useful Button Quest prototype?", "Default, hover or focus, pressed, and a clear success state.", "Distinct states help mouse, touch, and keyboard players know what happened."),
      gameCheckpoint("Test", "How do you check whether the button is understandable?", "Ask a tester what they expect to happen before they press it.", "Expectation before action reveals whether the label and affordance are doing their job.")
    ]
  }, 1),
  createGameProject({
    id: "icon-detective", emoji: "🕵️", level: "Warm-up", title: "Icon Detective", skills: "symbols · labels · clarity",
    brief: "Create a five-icon mystery menu for a little detective game. The icons can be playful, but a first-time player should never have to guess what a control does.",
    outcome: "A labeled icon menu with one visual rule shared across every symbol.",
    steps: [
      gameCheckpoint("Plan", "What makes an icon menu fair to a beginner?", "Choose familiar symbols and pair uncertain icons with short text labels.", "Labels remove ambiguity while the visual symbols become learnable over time."),
      gameCheckpoint("Sketch", "Which visual rule will make Icon Detective feel like one system?", "Use the same stroke weight, shape style, and button container for every icon.", "Shared visual rules make a small menu easier to scan."),
      gameCheckpoint("Test", "What should you ask a tester before revealing any labels?", "What do you think each icon will do?", "Their first interpretation tells you which icons need clearer cues.")
    ]
  }, 2),
  createGameProject({
    id: "moodboard-meteor", emoji: "☄️", level: "Warm-up", title: "Moodboard Meteor", skills: "references · art direction · theme",
    brief: "A comet has landed on a sleepy planet and needs a visual identity. Gather references that make its world feel calm, cosmic, and a little strange.",
    outcome: "A themed board with imagery, texture, color, type, and a short mood sentence.",
    steps: [
      gameCheckpoint("Plan", "What is the strongest starting point for Moodboard Meteor?", "Write a one-sentence feeling and collect references that support it.", "A clear emotional target keeps the board from becoming a random gallery."),
      gameCheckpoint("Sketch", "Which collection shows a coherent cosmic direction?", "Night-sky texture, soft orbit shapes, quiet violet tones, and readable rounded type.", "Related visual ingredients tell one story without needing a finished screen."),
      gameCheckpoint("Test", "How can you test the board before designing screens?", "Show it briefly and ask a viewer to name three feelings or adjectives.", "Their words reveal whether your intended mood is landing.")
    ]
  }, 3),
  createGameProject({
    id: "layout-labyrinth", emoji: "🧩", level: "Warm-up", title: "Layout Labyrinth", skills: "hierarchy · grids · scanning",
    brief: "Turn a simple maze game into a screen players can scan in seconds. Decide where the board, timer, lives, and one next move should live.",
    outcome: "A low-fidelity layout with a game board, HUD, and one primary action.",
    steps: [
      gameCheckpoint("Plan", "What should Layout Labyrinth decide before drawing rectangles?", "Which information is most important during play: board, goal, timer, or lives.", "Hierarchy starts by ranking what a player needs right now."),
      gameCheckpoint("Sketch", "Which layout best supports quick maze play?", "Give the board the largest area and group timer and lives together in a small HUD.", "The activity deserves the space; status information should be easy to glance at."),
      gameCheckpoint("Test", "What quick test checks your layout hierarchy?", "Show the wireframe for five seconds and ask what a player would do first.", "A short glance reveals whether the primary area is obvious.")
    ]
  }, 4),
  createGameProject({
    id: "type-trail", emoji: "🔤", level: "Warm-up", title: "Type Trail", skills: "typography · scale · readability",
    brief: "Design the text system for a trail-running score game. Players should be able to cheer for a win, read a tiny tip, and understand their next task without squinting.",
    outcome: "A type scale for title, score, instruction, button, and helper text.",
    steps: [
      gameCheckpoint("Plan", "What is the best first typography decision for Type Trail?", "Choose a readable body style, then define a small hierarchy for title, score, and instructions.", "A small scale makes text roles predictable and easier to maintain."),
      gameCheckpoint("Sketch", "Which type treatment helps players scan a timed game?", "A bold high-contrast score, a clear action label, and smaller supporting instruction text.", "Different roles need intentional contrast in size and weight."),
      gameCheckpoint("Test", "What should you test at a small phone size?", "Whether the instruction and button label remain readable without zooming.", "Readable type at realistic size is more useful than an impressive desktop headline.")
    ]
  }, 5),
  createGameProject({
    id: "onboarding-orchard", emoji: "🍎", level: "One-screen flow", title: "Onboarding Orchard", skills: "onboarding · choice · progress",
    brief: "A fruit-collecting game welcomes a new player with three tiny choices: nickname, favorite fruit, and first challenge. Make the setup feel like a game, not paperwork.",
    outcome: "A three-screen onboarding flow with a progress cue and friendly exit option.",
    steps: [
      gameCheckpoint("Plan", "What makes the Onboarding Orchard flow respectful of a new player?", "Ask only for choices that change the first play experience and make the steps feel optional when possible.", "Every question should earn its place by helping the player begin."),
      gameCheckpoint("Sketch", "Which progress cue is most useful in a three-step welcome flow?", "A short label such as “2 of 3” paired with the current choice.", "Specific progress reduces uncertainty without taking attention from the task."),
      gameCheckpoint("Test", "What should a first-time tester be able to explain after onboarding?", "What they chose and what will happen when they start playing.", "Good onboarding connects a small choice to a meaningful next moment.")
    ]
  }, 6),
  createGameProject({
    id: "accessibility-arcade", emoji: "♿", level: "One-screen flow", title: "Accessibility Arcade", skills: "contrast · focus · alternatives",
    brief: "Give a one-button arcade game an accessibility upgrade. Design it so a player can see focus, understand success without color alone, and play without a mouse.",
    outcome: "An accessibility checklist and annotated one-screen game mockup.",
    steps: [
      gameCheckpoint("Plan", "Which goal should Accessibility Arcade set first?", "Make every essential action understandable with more than color and reachable by keyboard.", "This protects the core game loop before adding decorative extras."),
      gameCheckpoint("Sketch", "Which control treatment is the strongest choice?", "A visible keyboard focus ring, a text label, and a success message with an icon plus words.", "Multiple cues make the interaction legible in more situations."),
      gameCheckpoint("Test", "What is a useful no-mouse test?", "Tab through the screen, trigger the action with the keyboard, and check that focus remains visible.", "Keyboard testing reveals a real path through the game.")
    ]
  }, 7),
  createGameProject({
    id: "menu-maze", emoji: "🗺️", level: "One-screen flow", title: "Menu Maze", skills: "navigation · grouping · labels",
    brief: "A fantasy maze game has six places to visit: play, map, backpack, badges, settings, and help. Make a menu that feels adventurous without hiding the important route.",
    outcome: "A labeled navigation menu with grouped secondary actions.",
    steps: [
      gameCheckpoint("Plan", "How should Menu Maze rank its destinations?", "Put the most frequent goal, starting a game, first and group lower-frequency settings separately.", "Frequency and urgency are practical ways to arrange a menu."),
      gameCheckpoint("Sketch", "Which label is clearest for beginning a new maze?", "“Play maze” with a short supportive icon.", "A direct verb tells a player what will happen next."),
      gameCheckpoint("Test", "What task should you give a menu tester?", "“Start a new maze, then find where your badges live.”", "A two-part task checks both the primary and secondary navigation paths.")
    ]
  }, 8),
  createGameProject({
    id: "scoreboard-studio", emoji: "🏆", level: "One-screen flow", title: "Scoreboard Studio", skills: "data · comparison · celebration",
    brief: "Create a score board for a friendly neighborhood game night. It should celebrate improvement, make ranks understandable, and avoid making anyone feel lost in a wall of numbers.",
    outcome: "A leaderboard with rank, name, score, recent change, and a personal highlight.",
    steps: [
      gameCheckpoint("Plan", "What question should Scoreboard Studio answer first?", "What should a returning player notice about their own progress?", "Personal progress creates meaning before a player compares themselves with everyone else."),
      gameCheckpoint("Sketch", "Which row design makes a leaderboard scannable?", "Align rank, player name, score, and a small change indicator in consistent columns.", "Consistent alignment lets eyes compare entries quickly."),
      gameCheckpoint("Test", "What do you ask someone viewing the board for the first time?", "Can you find your score and tell whether it went up or down?", "This checks the two most useful pieces of feedback on the screen.")
    ]
  }, 9),
  createGameProject({
    id: "tile-tale", emoji: "🀄", level: "Classic mechanics", title: "Tile Tale", skills: "cards · patterns · rule cues",
    brief: "Invent a matching game about tiny story tiles: clouds, keys, cats, and castles. Show just enough of the rules that a player can begin without a tutorial paragraph.",
    outcome: "A match-game start screen, tile style, and rule cue.",
    steps: [
      gameCheckpoint("Plan", "What is the most important promise Tile Tale must make?", "Show what counts as a match and what happens after a successful pair.", "A match game needs its rule and reward visible from the start."),
      gameCheckpoint("Sketch", "Which tile design will support memory play?", "Use one consistent back, distinct front illustrations, and enough spacing to prevent accidental taps.", "Consistency protects the memory mechanic while spacing supports touch."),
      gameCheckpoint("Test", "What should a tester understand after one turn?", "Whether they should reveal two tiles and what visual feedback means “match.”", "The first turn is the smallest useful lesson for the game.")
    ]
  }, 10),
  createGameProject({
    id: "character-capsule", emoji: "🧑‍🚀", level: "Classic mechanics", title: "Character Capsule", skills: "selection · comparison · personality",
    brief: "Design a character-select screen for a miniature space crew. Each explorer needs a personality, one simple ability, and a choice that feels meaningful without overloading a beginner.",
    outcome: "A three-character selection screen with clear comparisons and confirmation.",
    steps: [
      gameCheckpoint("Plan", "What makes Character Capsule choices meaningful but beginner-friendly?", "Give each character one clear strength and describe it in plain language.", "One memorable difference per option is easier to compare than a long stat list."),
      gameCheckpoint("Sketch", "Which character card content is most useful?", "A portrait, name, one ability, a short play-style line, and a select button.", "This balances personality with the information needed to choose."),
      gameCheckpoint("Test", "What should a tester be able to tell you after choosing?", "Why they picked that character and what they expect the ability to do.", "Clear expectations show the card communicated both theme and function.")
    ]
  }, 11),
  createGameProject({
    id: "soundscape-sprint", emoji: "🎧", level: "Classic mechanics", title: "Soundscape Sprint", skills: "audio cues · settings · feedback",
    brief: "Build an audio direction for a fast runner game: a calm loop, one jump sound, and a win cue. Make the controls kind to people who want silence or less intensity.",
    outcome: "A sound cue map and a compact audio settings panel.",
    steps: [
      gameCheckpoint("Plan", "What should Soundscape Sprint decide before adding effects?", "Which moments need an audio cue because the player benefits from feedback.", "Audio should reinforce useful moments, not fill every second with noise."),
      gameCheckpoint("Sketch", "Which setting is a respectful baseline?", "Separate music and effects controls, with a clear mute option.", "Independent controls let players shape the experience for their space and needs."),
      gameCheckpoint("Test", "What is a good non-audio check for the win moment?", "Confirm that a visible animation or message also communicates success.", "Important feedback should not rely on sound alone.")
    ]
  }, 12),
  createGameProject({
    id: "motion-potion", emoji: "🫧", level: "Classic mechanics", title: "Motion Potion", skills: "animation · timing · reduced motion",
    brief: "Give a potion-brewing game just enough motion to feel magical: a bubble, a button response, and a winning burst. Keep the movement purposeful and easy to reduce.",
    outcome: "A three-moment motion plan with an alternative reduced-motion version.",
    steps: [
      gameCheckpoint("Plan", "What makes Motion Potion animation purposeful?", "Use motion to show a change of state, such as mixing, pressing, or winning.", "Movement should communicate something, not compete with the game."),
      gameCheckpoint("Sketch", "Which animation timing is most likely to feel responsive?", "A short button response that begins immediately after the player acts.", "Quick feedback makes a small action feel connected to its result."),
      gameCheckpoint("Test", "What should the reduced-motion version preserve?", "The same clear success and state changes using still visual cues.", "Reducing motion should not remove important information.")
    ]
  }, 13),
  createGameProject({
    id: "narrative-nook", emoji: "📖", level: "Classic mechanics", title: "Narrative Nook", skills: "microcopy · choices · tone",
    brief: "Write a tiny choose-your-path mystery in a quiet library. Your screen needs a mood-setting line, two readable decisions, and a way to show the player their choice mattered.",
    outcome: "A narrative choice card with two branches and a consequence cue.",
    steps: [
      gameCheckpoint("Plan", "What should Narrative Nook establish before writing branches?", "The player’s immediate goal and the tone of the scene.", "A clear goal makes choices feel relevant rather than random."),
      gameCheckpoint("Sketch", "Which choice labels create a readable fork?", "Two action-led options that suggest different outcomes, such as “Follow the whisper” and “Inspect the ledger.”", "Specific verbs make each path feel distinct without giving away everything."),
      gameCheckpoint("Test", "What should a reader be able to say after one choice?", "What they chose and what consequence they noticed.", "This checks whether the branching feedback is visible and meaningful.")
    ]
  }, 14),
  createGameProject({
    id: "puzzle-pantry", emoji: "🍳", level: "Classic mechanics", title: "Puzzle Pantry", skills: "constraints · instructions · feedback",
    brief: "A kitchen puzzle asks players to arrange ingredients in the right order. Turn a recipe into a playful challenge with simple rules, encouraging errors, and a delicious win state.",
    outcome: "A puzzle board with a goal card, draggable ingredients, and clear feedback.",
    steps: [
      gameCheckpoint("Plan", "What is the clearest goal for Puzzle Pantry?", "State the finished recipe and the order or rule that determines success.", "A puzzle is fair when players can understand what they are trying to achieve."),
      gameCheckpoint("Sketch", "Which feedback is helpful after a wrong ingredient move?", "Keep the ingredient visible and explain the rule cue without revealing the whole answer.", "Gentle feedback teaches while preserving the challenge."),
      gameCheckpoint("Test", "What should you observe during a first solve attempt?", "Whether the player can explain the rule before trying random combinations.", "If the rule is unclear, the puzzle becomes guessing instead of reasoning.")
    ]
  }, 15),
  createGameProject({
    id: "level-loop", emoji: "🔁", level: "Systems", title: "Level Loop", skills: "progression · pacing · replay",
    brief: "Map three tiny levels for a balloon-pop game: learn, remix, celebrate. The loop should introduce one idea at a time and give players a reason to try another round.",
    outcome: "A three-level progression map with a new twist in each level.",
    steps: [
      gameCheckpoint("Plan", "What is a kind first level for Level Loop?", "Teach one action in a low-pressure space before adding a twist.", "A safe introduction lets players build confidence before difficulty rises."),
      gameCheckpoint("Sketch", "Which sequence shows healthy progression?", "Learn the pop action, add a moving target, then combine targets for a playful final round.", "Each level reuses a learned skill and adds one understandable change."),
      gameCheckpoint("Test", "What is useful evidence that the progression works?", "A tester reaches level two knowing the core action without needing the instruction repeated.", "Successful transfer shows the first level taught the foundation.")
    ]
  }, 16),
  createGameProject({
    id: "difficulty-dial", emoji: "🎚️", level: "Systems", title: "Difficulty Dial", skills: "challenge · choice · fairness",
    brief: "Give a bubble-sort game a friendly difficulty dial. Players should understand what changes at each setting and be able to choose a challenge that feels right today.",
    outcome: "A three-setting difficulty picker with plain-language consequences.",
    steps: [
      gameCheckpoint("Plan", "What should Difficulty Dial explain for each setting?", "Which specific part changes, such as time, hints, or target complexity.", "Named consequences turn a vague label into an informed choice."),
      gameCheckpoint("Sketch", "Which label set is clearest for a beginner game?", "“Practice,” “Play,” and “Challenge,” each with a short description of the change.", "Plain language is more inviting than unexplained expert terminology."),
      gameCheckpoint("Test", "What question checks whether players can choose fairly?", "Can you tell what will be easier or harder before you start?", "Players should understand the tradeoff before committing to a level.")
    ]
  }, 17),
  createGameProject({
    id: "reward-rocket", emoji: "🚀", level: "Systems", title: "Reward Rocket", skills: "rewards · progress · motivation",
    brief: "Create a rocket-fuel reward system for completing short missions. Celebrate real progress without turning every click into a confetti explosion.",
    outcome: "A reward ladder with one immediate cue, one milestone, and one collection view.",
    steps: [
      gameCheckpoint("Plan", "What makes a Reward Rocket reward meaningful?", "Connect it to a real action or milestone the player can understand.", "A reward feels earned when its trigger is clear and tied to progress."),
      gameCheckpoint("Sketch", "Which reward rhythm is balanced?", "A small cue after a mission, a bigger badge after a milestone, and a place to revisit the collection.", "Layered rewards keep feedback positive without overwhelming the loop."),
      gameCheckpoint("Test", "What should a player understand after earning fuel?", "What they did to earn it and what progress it represents.", "Clear cause and effect makes reward systems feel fair.")
    ]
  }, 18),
  createGameProject({
    id: "mapmakers-trail", emoji: "🧭", level: "Systems", title: "Mapmaker’s Trail", skills: "maps · wayfinding · progress",
    brief: "Design a playful island map for a game with four short zones. A player should recognize their current spot, the next destination, and a tempting optional detour.",
    outcome: "A zone map with current, next, locked, and optional markers.",
    steps: [
      gameCheckpoint("Plan", "What information matters most on Mapmaker’s Trail?", "Where the player is, where they can go next, and what is still locked.", "Wayfinding is strongest when the current route is never a mystery."),
      gameCheckpoint("Sketch", "Which marker system is easiest to scan?", "Use distinct labels or shapes for current, next, completed, optional, and locked zones.", "Multiple visual cues make status clearer than color alone."),
      gameCheckpoint("Test", "What task should you give a map tester?", "“Show me your next required stop and one optional place you could visit.”", "This checks both the main route and optional discovery.")
    ]
  }, 19),
  createGameProject({
    id: "hud-harmony", emoji: "🧠", level: "Systems", title: "HUD Harmony", skills: "HUD · priorities · restraint",
    brief: "Create a heads-up display for a mellow space gardener. Players need to see oxygen, seeds, and the next objective without the display covering the tiny planet they came to enjoy.",
    outcome: "A calm HUD layout with prioritized live information.",
    steps: [
      gameCheckpoint("Plan", "How should HUD Harmony choose what stays visible during play?", "Keep only information that changes a player’s next decision on the main screen.", "A HUD is useful when it supports action instead of narrating everything."),
      gameCheckpoint("Sketch", "Which grouping best supports a space gardener?", "Place oxygen and active objective together, keep seeds nearby but secondary, and leave the world unobstructed.", "Related urgent information should be quick to scan while the play space stays open."),
      gameCheckpoint("Test", "What first-glance check should you run?", "Ask a tester what resource is urgent and what they should do next.", "A clear HUD answers both questions without a tutorial.")
    ]
  }, 20),
  createGameProject({
    id: "boss-blueprint", emoji: "🐉", level: "Systems", title: "Boss Blueprint", skills: "telegraphing · patterns · accessibility",
    brief: "Design a playful giant-library-cat boss that is dramatic, never cheap. Players should be able to notice a pattern, react in time, and learn from a miss.",
    outcome: "A boss pattern sheet with tell, action, safe response, and recovery feedback.",
    steps: [
      gameCheckpoint("Plan", "What makes a Boss Blueprint challenge feel fair?", "Give each powerful move a recognizable tell before it happens.", "A telegraphed pattern lets skill, not surprise, decide the outcome."),
      gameCheckpoint("Sketch", "Which pattern is easiest for a beginner to learn?", "A visible paw-tap tell, a short swipe, then a safe pause to respond.", "A repeated, readable rhythm creates a learnable loop."),
      gameCheckpoint("Test", "What should a tester be able to describe after one miss?", "What warned them, what happened, and what they could try next time.", "Useful failure feedback turns a loss into a next-step lesson.")
    ]
  }, 21),
  createGameProject({
    id: "economy-emporium", emoji: "🪙", level: "Systems", title: "Economy Emporium", skills: "resources · pricing · choices",
    brief: "Give a tiny bakery game coins, upgrades, and choices without turning it into spreadsheet homework. Let a player understand what they can afford and why an upgrade helps.",
    outcome: "A simple shop card system with price, benefit, balance, and purchase feedback.",
    steps: [
      gameCheckpoint("Plan", "What should Economy Emporium make clear before showing a shop?", "What players earn, what they can spend it on, and why each option helps.", "A visible loop makes resource decisions feel intentional instead of mysterious."),
      gameCheckpoint("Sketch", "Which upgrade card is most informative?", "Show the price, one plain-language benefit, and whether the player can afford it.", "A compact comparison helps players decide without calculating hidden values."),
      gameCheckpoint("Test", "What should you ask after a tester makes a purchase?", "Can you explain what you gave up and what changed in the game?", "This checks whether the economy supports meaningful tradeoffs.")
    ]
  }, 22),
  createGameProject({
    id: "coop-campfire", emoji: "🔥", level: "Systems", title: "Co-op Campfire", skills: "cooperation · roles · communication",
    brief: "Sketch a two-player campfire game where one person gathers stories and one person tends the fire. Make the roles complementary, friendly, and understandable without a long rulebook.",
    outcome: "A co-op role card pair and a shared-goal screen.",
    steps: [
      gameCheckpoint("Plan", "What makes Co-op Campfire roles worth playing together?", "Give each player a different helpful action that contributes to one shared goal.", "Complementary roles create cooperation instead of two people doing the same task."),
      gameCheckpoint("Sketch", "Which shared goal is clearest?", "Keep the fire warm through three story rounds while both players contribute a simple action.", "A short, visible shared objective keeps coordination grounded."),
      gameCheckpoint("Test", "What should you observe in a two-player test?", "Whether each person can describe their role and when they need the other player.", "That moment of mutual need is the heart of a co-op interaction.")
    ]
  }, 23),
  createGameProject({
    id: "thumb-quest", emoji: "📱", level: "Mobile play", title: "Thumb Quest", skills: "mobile · reach · touch targets",
    brief: "Adapt a tiny treasure game for one-handed phone play. The key action needs to be reachable, tappable, and safe from accidental touches on small screens.",
    outcome: "A mobile game screen with a reachable primary action and generous touch target.",
    steps: [
      gameCheckpoint("Plan", "What should Thumb Quest protect first on a phone?", "The primary action’s reachability and the size of its touch target.", "The most-used action deserves the easiest, safest placement."),
      gameCheckpoint("Sketch", "Which placement is friendliest for one-handed play?", "Put the primary action in an easy-to-reach lower area with breathing room around it.", "Lower reachable zones and spacing reduce accidental taps."),
      gameCheckpoint("Test", "What simple mobile test is useful?", "Try the screen with one thumb and note any action that requires stretching or pinching.", "Realistic posture reveals issues a desktop mockup can hide.")
    ]
  }, 24),
  createGameProject({
    id: "inclusive-input", emoji: "⌨️", level: "Mobile play", title: "Inclusive Input", skills: "inputs · remapping · alternatives",
    brief: "A rhythm game needs taps, keys, and a way to slow the beat. Design inputs that invite different bodies and different devices into the same tiny challenge.",
    outcome: "An input map with keyboard, touch, and slower-play alternatives.",
    steps: [
      gameCheckpoint("Plan", "What is the most inclusive starting decision for Inclusive Input?", "List the essential action, then offer more than one practical way to trigger it.", "Alternative inputs protect the game’s core without requiring one physical method."),
      gameCheckpoint("Sketch", "Which control option is strongest?", "Support tap and keyboard activation, explain both, and include a slower timing setting.", "Clear alternatives make the rule reachable instead of hidden in settings."),
      gameCheckpoint("Test", "What should a keyboard-only player be able to complete?", "The entire core rhythm round, including starting and retrying it.", "A complete path matters more than a single accessible button.")
    ]
  }, 25),
  createGameProject({
    id: "data-dash", emoji: "📊", level: "Mobile play", title: "Data Dash", skills: "metrics · learning · privacy",
    brief: "Design a personal practice recap for a sprint game. Celebrate useful patterns—like favorite mode and best streak—without turning every player into a data analyst.",
    outcome: "A simple recap card with one achievement, one trend, and one next suggestion.",
    steps: [
      gameCheckpoint("Plan", "Which metric is most helpful for Data Dash?", "A small measure that helps the player choose what to practice next.", "Good metrics guide a decision instead of collecting numbers for their own sake."),
      gameCheckpoint("Sketch", "Which recap is clearest?", "Show a best streak, a recent trend, and one friendly suggested next round.", "A small story about progress is easier to use than a dense dashboard."),
      gameCheckpoint("Test", "What should you ask after someone reads the recap?", "Can you name one thing you improved and one thing you might try next?", "Useful feedback should translate into a next action.")
    ]
  }, 26),
  createGameProject({
    id: "ethical-arcade", emoji: "🌱", level: "Mobile play", title: "Ethical Arcade", skills: "consent · respect · calm design",
    brief: "Redesign a token game so it is playful without pressuring people to keep spending, sharing, or returning. Make the kinder choice the easy choice.",
    outcome: "A calm game economy screen with transparent choices and a respectful pause option.",
    steps: [
      gameCheckpoint("Plan", "What promise should Ethical Arcade make to players?", "Explain optional choices plainly and avoid using pressure or confusion to drive an action.", "Transparent choices let players stay in control of their time and attention."),
      gameCheckpoint("Sketch", "Which purchase treatment is most respectful?", "A clear price, a plain-language benefit, and no countdown that disguises the choice.", "Honest information supports consent more than manufactured urgency."),
      gameCheckpoint("Test", "What question checks the screen’s tone?", "Do you feel you can pause or leave without losing something unfair?", "A healthy game respects a player’s ability to stop.")
    ]
  }, 27),
  createGameProject({
    id: "playtest-lab", emoji: "🧪", level: "Polish", title: "Playtest Lab", skills: "research · observation · iteration",
    brief: "Run a tiny playtest for a coin-catching game. Write a task, observe without rescuing the player too early, and turn one finding into a better second version.",
    outcome: "A three-question playtest plan and one prioritized improvement.",
    steps: [
      gameCheckpoint("Plan", "What is a strong first playtest task?", "Ask a player to complete one realistic goal without explaining the interface first.", "A real task shows what the design communicates on its own."),
      gameCheckpoint("Sketch", "Which observation note is most useful?", "Record where the player hesitates, what they say, and what they try next.", "Specific behavior is more useful than a vague “they liked it.”"),
      gameCheckpoint("Test", "What should you change after finding one clear issue?", "Make one focused revision, then test the same task again.", "Small, testable iterations make learning visible.")
    ]
  }, 28),
  createGameProject({
    id: "tiny-game-jam", emoji: "🎉", level: "Polish", title: "Tiny Game Jam", skills: "scope · release · reflection",
    brief: "Pull together a weekend-sized game idea: one verb, one feeling, one tiny ending. Package it as a friendly playable prototype and celebrate what you learned.",
    outcome: "A one-page game jam brief, a playable core loop, and a release checklist.",
    steps: [
      gameCheckpoint("Plan", "What keeps a Tiny Game Jam idea finishable?", "Choose one core action, one mood, and one small win condition.", "A narrow promise gives a beginner project room to become complete."),
      gameCheckpoint("Sketch", "Which release checklist is most useful?", "Check the start, core action, win or retry state, controls, and one piece of player-facing guidance.", "A small checklist protects the path a real player will take."),
      gameCheckpoint("Test", "What is the best final reflection question?", "What did a new player understand quickly, and what would you improve in a second jam?", "Reflection turns a finished project into a reusable design lesson.")
    ]
  }, 29)
];

const buildingGameProjects = [
  createGameProject({
    id: "star-tap", emoji: "⭐", level: "Input", title: "Star Tap", skills: "events · score · reset",
    brief: "Build a one-screen game where a glowing star hops to a new spot when clicked. Every tap earns one point, and a reset lets a friend start fresh.",
    outcome: "A working tap target, live score, and reset control.",
    steps: [
      gameCheckpoint("Plan", "What is the smallest reliable first version of Star Tap?", "One clickable star that adds one point to a visible score.", "A tiny working loop is easier to test before adding movement or effects."),
      gameCheckpoint("Build", "Which event should make the score change?", "A click or tap handler attached to the star button.", "An explicit event connects the player action to the game state."),
      gameCheckpoint("Test", "What should you check after adding reset?", "That it restores both the score and the starting star state.", "A reset is only useful if it returns the whole small game to a known condition.")
    ]
  }, 30),
  createGameProject({
    id: "number-nebula", emoji: "🔢", level: "Input", title: "Number Nebula", skills: "input · random · conditions",
    brief: "Make a friendly number-guessing nebula. The player picks a number, gets a warm high-or-low clue, and earns a small constellation when they find the secret.",
    outcome: "A bounded guess input, clue message, and win state.",
    steps: [
      gameCheckpoint("Plan", "What keeps Number Nebula fair for a first version?", "Choose a small visible range and generate one secret number within it.", "A clear range lets players reason about their next guess."),
      gameCheckpoint("Build", "Which feedback helps after a wrong guess?", "Tell the player whether the secret number is higher or lower.", "A directional clue turns random guessing into a learnable game."),
      gameCheckpoint("Test", "What should you verify before declaring a win?", "That guesses outside the range receive a helpful message instead of changing the game.", "Validation keeps the rules predictable and protects the state.")
    ]
  }, 31),
  createGameProject({
    id: "reaction-rocket", emoji: "🚀", level: "Input", title: "Reaction Rocket", skills: "timing · states · feedback",
    brief: "Launch a tiny rocket only after the launch pad turns green. A too-early tap gets a playful “steady!” message; a well-timed tap records a reaction time.",
    outcome: "A wait state, go state, early-tap feedback, and time result.",
    steps: [
      gameCheckpoint("Plan", "Which states does Reaction Rocket need before timing anything?", "Waiting, ready-to-tap, and result states.", "Named states prevent the game from accepting a tap at the wrong moment."),
      gameCheckpoint("Build", "When should the reaction timer begin?", "At the exact moment the launch pad changes to the ready state.", "Starting at the visual signal makes the measurement meaningful."),
      gameCheckpoint("Test", "How should an early tap behave?", "Show a clear early-tap result and restart the waiting state without recording a false win.", "Feedback makes the rule understandable while protecting the score.")
    ]
  }, 32),
  createGameProject({
    id: "coin-counter-cove", emoji: "🪙", level: "Input", title: "Coin Counter Cove", skills: "state · buttons · totals",
    brief: "Build a pirate cove where three coin buttons fill a treasure chest. Let players add, remove, and reset coins while the total stays honest.",
    outcome: "Three controls, a live coin total, and a safe zero limit.",
    steps: [
      gameCheckpoint("Plan", "What is the single source of truth for Coin Counter Cove?", "One number in game state that represents the current coin total.", "A single state value keeps every display and button action in sync."),
      gameCheckpoint("Build", "What should happen when the player removes coins at zero?", "Keep the total at zero and give calm feedback rather than showing a negative total.", "A small guard condition prevents an impossible game state."),
      gameCheckpoint("Test", "Which test proves the count is reliable?", "Add and remove coins in different orders, then reset and confirm the display matches state.", "Changing actions in sequence catches many simple state mistakes.")
    ]
  }, 33),
  createGameProject({
    id: "keypath-maze", emoji: "⌨️", level: "Input", title: "Keypath Maze", skills: "keyboard · grid · bounds",
    brief: "Code a tiny maze where an explorer moves with arrow keys. The explorer should never walk through a wall or escape the board, and the goal should feel reachable.",
    outcome: "A keyboard-controlled grid with walls, goal, and boundary checks.",
    steps: [
      gameCheckpoint("Plan", "What should Keypath Maze represent before moving a character?", "A small grid that marks open spaces, walls, the start, and the goal.", "A simple model gives movement rules something concrete to check."),
      gameCheckpoint("Build", "What must happen before updating the explorer’s position?", "Check that the next cell is inside the board and not a wall.", "Validate a move first so the visual state stays legal."),
      gameCheckpoint("Test", "What keyboard path should you try first?", "Move into each edge and one wall, then reach the goal using only the arrow keys.", "This verifies both constraints and the intended accessible control path.")
    ]
  }, 34),
  createGameProject({
    id: "memory-moon-match", emoji: "🌙", level: "Classic loop", title: "Memory Moon Match", skills: "arrays · pairs · turn logic",
    brief: "Build a moon-themed memory game with six paired cards. Players flip two at a time, matched pairs stay revealed, and mismatches turn back after a brief pause.",
    outcome: "A shuffled pair board, two-card turn logic, and match counter.",
    steps: [
      gameCheckpoint("Plan", "What data shape makes Memory Moon Match manageable?", "An array of card objects with a pair value and a revealed or matched state.", "A small card model lets the UI render from the game state."),
      gameCheckpoint("Build", "What should happen after the second non-matching card flips?", "Temporarily lock new flips, then hide the two cards after a short pause.", "A short lock prevents a player from turning three cards during the mismatch delay."),
      gameCheckpoint("Test", "What final condition should trigger the win message?", "Every pair has a matched state, not merely two cards currently showing.", "The win rule needs to track lasting matches across the whole board.")
    ]
  }, 35),
  createGameProject({
    id: "pebble-leaf-cloud", emoji: "🍃", level: "Classic loop", title: "Pebble–Leaf–Cloud", skills: "randomness · comparisons · rounds",
    brief: "Create an original rock-paper-scissors-style duel: pebble beats leaf, leaf catches cloud, cloud floats over pebble. Give each round a clear result and a running match score.",
    outcome: "A three-choice round, computer choice, result message, and score.",
    steps: [
      gameCheckpoint("Plan", "What should Pebble–Leaf–Cloud define before code?", "The complete win relationship for all three choices, including ties.", "Writing the rules first keeps conditional logic from growing confusing."),
      gameCheckpoint("Build", "What is the fairest way to generate the opponent’s move?", "Randomly select one item from the same three-choice list used by the player.", "One shared list keeps the game options consistent."),
      gameCheckpoint("Test", "Which case is easy to forget but essential?", "A tie result that explains both players chose the same symbol.", "A full comparison game needs a calm outcome for every possible round.")
    ]
  }, 36),
  createGameProject({
    id: "garden-gopher", emoji: "🌱", level: "Classic loop", title: "Garden Gopher", skills: "random positions · timer · cleanup",
    brief: "Make a gentle whack-a-mole garden where a gopher pops up in a random plot. Players earn seeds for quick taps, but the garden should stop cleanly when time runs out.",
    outcome: "A timed random target, score, and end-of-round state.",
    steps: [
      gameCheckpoint("Plan", "What makes Garden Gopher’s core loop easy to understand?", "Show one active garden plot at a time, then move the gopher after a tap or short delay.", "One target creates a clear rule before you add speed or bonuses."),
      gameCheckpoint("Build", "What should happen when the round timer reaches zero?", "Stop the gopher movement, disable scoring taps, and show the final seed count.", "Cleaning up active timers prevents the game from continuing after it says it ended."),
      gameCheckpoint("Test", "What race condition should you test?", "Tap just as time expires and confirm the score does not change after the end screen.", "Near-boundary actions are where timer games often behave unexpectedly.")
    ]
  }, 37),
  createGameProject({
    id: "quiz-quest", emoji: "❓", level: "Classic loop", title: "Quiz Quest", skills: "questions · feedback · progress",
    brief: "Build a five-question creature quiz with instant explanations. A player should see the current number, learn from a miss, and reach a real finish screen.",
    outcome: "A question array, four choices, feedback, progress, and results.",
    steps: [
      gameCheckpoint("Plan", "How should Quiz Quest store its questions?", "Use an array of objects with the question, choices, correct answer, and short explanation.", "A data-driven question list makes the quiz easier to render and extend."),
      gameCheckpoint("Build", "What should happen after an answer is selected?", "Disable the choices, mark the result, show the explanation, and then allow the next question.", "This makes feedback readable and prevents double scoring."),
      gameCheckpoint("Test", "What should the finish screen report?", "The final score, total questions, and a clear option to play again.", "A result needs context and a simple next action.")
    ]
  }, 38),
  createGameProject({
    id: "story-switchboard", emoji: "📟", level: "Classic loop", title: "Story Switchboard", skills: "branches · state · endings",
    brief: "Code a mini sci-fi story where three choices route a signal through a mysterious station. Each choice changes the next scene, but the player can always understand the story they shaped.",
    outcome: "A small scene map, saved choices, and two readable endings.",
    steps: [
      gameCheckpoint("Plan", "What keeps Story Switchboard small enough to finish?", "Map three scenes and two endings before writing every line of dialogue.", "A short scene map limits branching while still letting choices matter."),
      gameCheckpoint("Build", "What should each choice save in state?", "The selected route or consequence needed to decide the next scene and ending.", "Store only the information the later story actually needs."),
      gameCheckpoint("Test", "How do you test a branching story?", "Follow every choice path at least once and confirm each reaches a readable ending.", "Path coverage catches dead ends and missing state transitions.")
    ]
  }, 39),
  createGameProject({
    id: "dice-duel", emoji: "🎲", level: "Challenge", title: "Dice Duel", skills: "randomness · rounds · win rules",
    brief: "Build a two-round dice duel against a friendly robot. Each roll should be visible, totals should be honest, and the game should clearly settle ties.",
    outcome: "Roll controls, visible dice values, cumulative totals, and tie handling.",
    steps: [
      gameCheckpoint("Plan", "What must Dice Duel decide before rendering a die?", "How many rounds happen, how totals are calculated, and how a tie resolves.", "Clear win rules are the foundation of a short competitive game."),
      gameCheckpoint("Build", "What range should a fair six-sided die generator produce?", "An integer from 1 through 6 inclusive.", "The bounds need to match every visible face of the die."),
      gameCheckpoint("Test", "What result should you verify deliberately?", "A tied final total that produces a tie message rather than an accidental win.", "Tie paths deserve the same attention as normal wins and losses.")
    ]
  }, 40),
  createGameProject({
    id: "typing-meteor", emoji: "☄️", level: "Challenge", title: "Typing Meteor", skills: "text input · matching · pace",
    brief: "Make a meteor defense game where a short word falls into view and the player types it before impact. Start slowly, celebrate correct words, and keep errors encouraging.",
    outcome: "A word prompt, typed comparison, streak, and gentle speed ramp.",
    steps: [
      gameCheckpoint("Plan", "What is a beginner-friendly first difficulty for Typing Meteor?", "Use short common words, one visible target, and a generous time window.", "A simple first challenge lets the player learn the input rule."),
      gameCheckpoint("Build", "When should a typed word count as correct?", "After normalizing the input and comparing it to the current target word.", "Normalization prevents harmless capitalization or whitespace differences from feeling unfair."),
      gameCheckpoint("Test", "What feedback should an incorrect entry give?", "Keep the target visible and invite another try without resetting unrelated progress.", "Supportive feedback keeps a practice game from becoming punishing.")
    ]
  }, 41),
  createGameProject({
    id: "pocket-garden-clicker", emoji: "🪴", level: "Challenge", title: "Pocket Garden Clicker", skills: "resources · upgrades · persistence",
    brief: "Grow a pocket garden by tapping for dew and spending it on one useful upgrade. Keep the math small, make the next upgrade visible, and save a tiny amount of progress locally.",
    outcome: "A dew counter, one upgrade, cost check, and local saved progress.",
    steps: [
      gameCheckpoint("Plan", "What makes Pocket Garden Clicker’s first economy understandable?", "One resource, one upgrade with a visible cost, and one clear benefit.", "A small loop lets players learn cause and effect before more systems appear."),
      gameCheckpoint("Build", "What should happen if the player cannot afford an upgrade?", "Keep the purchase unavailable or explain the missing dew without subtracting anything.", "A cost guard protects the game state and explains the next goal."),
      gameCheckpoint("Test", "What should local saving restore on refresh?", "The dew total and purchased upgrade state, then render the matching UI.", "Persistence only works if the display is rebuilt from restored state.")
    ]
  }, 42),
  createGameProject({
    id: "echo-simon", emoji: "🔊", level: "Challenge", title: "Echo Simon", skills: "sequences · timing · input lock",
    brief: "Build a light-and-sound memory sequence game. The game plays a growing pattern, waits for the player’s echo, and shows a friendly retry when the pattern breaks.",
    outcome: "A generated sequence, playback mode, player input mode, and round counter.",
    steps: [
      gameCheckpoint("Plan", "Which state separation keeps Echo Simon stable?", "Use one mode for computer playback and a separate mode for player input.", "A clear mode prevents taps from being counted while the game is still showing the pattern."),
      gameCheckpoint("Build", "When should the sequence grow?", "Only after the player repeats the entire current pattern correctly.", "Growing after a completed echo creates one understandable challenge step at a time."),
      gameCheckpoint("Test", "What should a wrong input do?", "Stop the current round, explain the miss, and offer a clean retry with the correct starting state.", "A clean reset avoids leaving half-finished pattern data behind.")
    ]
  }, 43),
  createGameProject({
    id: "color-catch-comet", emoji: "🌈", level: "Challenge", title: "Color Catch Comet", skills: "collision · targets · feedback",
    brief: "Make a color-catching game where a basket can only collect comets matching its current color. Give a correct catch a satisfying burst and make a wrong catch easy to understand.",
    outcome: "A moving target, color match rule, score, and miss feedback.",
    steps: [
      gameCheckpoint("Plan", "What is the essential rule Color Catch Comet must show?", "Which basket color can collect which comet color right now.", "A visible rule keeps a fast reaction game from becoming arbitrary."),
      gameCheckpoint("Build", "What should your collision check compare?", "Whether the comet overlaps the basket and whether their active colors match.", "Both position and rule state decide a valid catch."),
      gameCheckpoint("Test", "Which feedback helps after a wrong-color catch?", "Show the expected color and preserve enough time for the player to adjust.", "Clear feedback turns a miss into a learnable next move.")
    ]
  }, 44),
  createGameProject({
    id: "canvas-critter-doodle", emoji: "🖍️", level: "Visual build", title: "Canvas Critter Doodle", skills: "canvas · coordinates · drawing",
    brief: "Use a drawing surface to make a lovable forest critter from circles, lines, and colors. Add one interactive detail, like a blinking eye or a hat that changes on click.",
    outcome: "A drawn critter composed from simple shapes and one interaction.",
    steps: [
      gameCheckpoint("Plan", "What is the best way to begin Canvas Critter Doodle?", "Break the critter into a few simple shapes with named positions and colors.", "Simple geometry makes a complex illustration easier to build and adjust."),
      gameCheckpoint("Build", "What should an interactive click translate into on a canvas?", "Pointer coordinates that can be checked against the area of the critter detail.", "Canvas interaction needs location data because shapes are not separate HTML buttons."),
      gameCheckpoint("Test", "What should you test after resizing the drawing area?", "That the critter remains visible, aligned, and still responds in the intended region.", "Visual coordinate work often changes when the canvas size changes.")
    ]
  }, 45),
  createGameProject({
    id: "snake-sprout", emoji: "🐍", level: "Visual build", title: "Snake Sprout", skills: "game loop · grid · growth",
    brief: "Grow a tiny garden snake across a grid as it eats sprouts. Start with steady movement, clear collision rules, and a reset that makes a new round feel inviting.",
    outcome: "A grid snake, food spawn, growth, collision, and restart.",
    steps: [
      gameCheckpoint("Plan", "What should Snake Sprout model in state?", "An ordered list of snake cells, a direction, and one food cell.", "Those three pieces are enough to render and update the classic loop."),
      gameCheckpoint("Build", "What should happen when the snake reaches a sprout?", "Grow the snake, increase the score, and place new food in an unoccupied cell.", "New food must not appear inside the snake or become unreachable."),
      gameCheckpoint("Test", "What collision cases should you test?", "The board edge and the snake moving into its own body.", "Both conditions should end the run with a clear restart path.")
    ]
  }, 46),
  createGameProject({
    id: "paddle-planet", emoji: "🪐", level: "Visual build", title: "Paddle Planet", skills: "physics · input · bounce",
    brief: "Build a tiny paddle game that keeps a meteor orbiting a planet. Move the paddle, bounce the meteor, and show a small life counter when it falls past the edge.",
    outcome: "A movable paddle, bouncing ball, lives, and a gentle game-over state.",
    steps: [
      gameCheckpoint("Plan", "What values should Paddle Planet update every frame?", "The meteor position and velocity, plus the paddle position from player input.", "Motion needs position and velocity, while input moves the player-controlled surface."),
      gameCheckpoint("Build", "When the meteor reaches the paddle, what should change?", "Reverse the vertical direction when it overlaps the paddle from above.", "A directional collision rule creates a believable bounce instead of random movement."),
      gameCheckpoint("Test", "What should happen after the last life is lost?", "Stop the active loop, show the result, and offer a restart that resets lives and position.", "Ending and restarting cleanly avoids runaway animation loops.")
    ]
  }, 47),
  createGameProject({
    id: "brick-bloom", emoji: "🧱", level: "Visual build", title: "Brick Bloom", skills: "collections · collisions · levels",
    brief: "Turn a flower wall into a gentle brick breaker. Every hit clears one bloom, score rises, and the last bloom opens a tiny “garden restored” level complete moment.",
    outcome: "A brick collection, hit removal, score, and level-complete state.",
    steps: [
      gameCheckpoint("Plan", "How should Brick Bloom represent its flowers?", "As a collection of small blocks, each with position and active state.", "A collection makes it possible to render, hit-test, and remove each bloom."),
      gameCheckpoint("Build", "What should a successful ball-and-bloom collision do?", "Mark that bloom inactive, update the score, and adjust the ball direction once.", "One collision should produce one predictable game update."),
      gameCheckpoint("Test", "What should trigger the garden-restored message?", "When no active blooms remain in the collection.", "A data-based win check works even if the level layout changes.")
    ]
  }, 48),
  createGameProject({
    id: "cloudstep-jumper", emoji: "☁️", level: "Visual build", title: "Cloudstep Jumper", skills: "gravity · platforms · camera",
    brief: "Build a small sky jumper where a character lands on clouds and climbs toward a rainbow. Keep the first version simple: gravity, platforms, landing, and one victory height.",
    outcome: "A gravity loop, platforms, landing check, and height goal.",
    steps: [
      gameCheckpoint("Plan", "What is the smallest playable Cloudstep Jumper loop?", "Gravity pulls the character down, a jump launches up, and platforms catch the character.", "Those three rules create a clear platforming foundation."),
      gameCheckpoint("Build", "When should a landing count?", "When the character is falling and their feet cross onto the top of a platform.", "Direction matters so a jump from below does not count as landing on top."),
      gameCheckpoint("Test", "What should your first win condition be?", "Reach a clearly marked high platform or rainbow goal.", "A visible goal makes a prototype feel finishable before adding levels.")
    ]
  }, 49),
  createGameProject({
    id: "rooftop-runner", emoji: "🏙️", level: "Polish", title: "Rooftop Runner", skills: "speed · obstacles · difficulty",
    brief: "Create an endless rooftop runner with one jump, a few friendly obstacles, and a speed that increases slowly. Players should see why a run ended and want to try once more.",
    outcome: "A running loop, obstacle spawn, increasing pace, and retry screen.",
    steps: [
      gameCheckpoint("Plan", "What keeps Rooftop Runner beginner-friendly at the start?", "One reliable jump action and obstacles spaced far enough apart to learn the timing.", "Start with a stable rhythm before increasing pressure."),
      gameCheckpoint("Build", "How should difficulty rise in an early prototype?", "Increase speed or shorten spacing gradually after predictable progress milestones.", "Gradual change gives players time to adapt and makes difficulty feel earned."),
      gameCheckpoint("Test", "What should a game-over message include?", "The distance or score, a short reason for the collision, and a visible retry button.", "A respectful ending provides context and a clear next action.")
    ]
  }, 50),
  createGameProject({
    id: "space-dodger", emoji: "🛸", level: "Polish", title: "Space Dodger", skills: "movement · spawn · pause",
    brief: "Guide a little ship through a meteor shower. Let a player dodge with simple movement, pause safely, and choose whether to restart after a high score.",
    outcome: "A player ship, obstacle spawner, pause state, and high-score check.",
    steps: [
      gameCheckpoint("Plan", "What state should Space Dodger keep separate from active play?", "A paused state that freezes movement and ignores gameplay input until resumed.", "Pause is a real game state, not just a visual overlay."),
      gameCheckpoint("Build", "What should meteor spawning avoid?", "Creating an unavoidable obstacle directly on top of the player’s current ship position.", "Fair spawn rules give players a chance to react."),
      gameCheckpoint("Test", "What should happen if pause is pressed twice?", "The game should reliably alternate between paused and active without duplicating loops.", "Repeat interactions reveal whether timers and event handling are clean.")
    ]
  }, 51),
  createGameProject({
    id: "sprout-sentinel", emoji: "🌻", level: "Polish", title: "Sprout Sentinel", skills: "waves · placement · strategy",
    brief: "Make a pocket tower-defense garden where a player places one helpful sprout to slow wandering pests. Focus on one lane, one resource, and waves a player can read.",
    outcome: "A lane, placeable defender, moving pest, resource, and wave counter.",
    steps: [
      gameCheckpoint("Plan", "What is the smartest first scope for Sprout Sentinel?", "One lane, one defender type, one enemy type, and a short wave goal.", "A narrow loop lets you learn placement and movement before adding a whole map."),
      gameCheckpoint("Build", "What should placing a defender check first?", "That the player has enough resource and the chosen spot is available.", "Validate a placement before subtracting a resource or creating a duplicate tower."),
      gameCheckpoint("Test", "What should be clear when a wave begins?", "How many pests are coming and whether the player has time to prepare.", "Readable wave feedback lets strategy replace surprise.")
    ]
  }, 52),
  createGameProject({
    id: "slide-and-shine", emoji: "✨", level: "Polish", title: "Slide & Shine", skills: "puzzles · board state · win check",
    brief: "Build a sliding-tile light puzzle that turns a dark room bright. Let players move one tile at a time, offer an undo or reset, and celebrate a solved image.",
    outcome: "A tile grid, legal-move check, reset, and solved state.",
    steps: [
      gameCheckpoint("Plan", "What data best represents Slide & Shine’s board?", "An ordered list or grid of tile positions with one empty space.", "A board model makes legal swaps and solved checks possible."),
      gameCheckpoint("Build", "When should a tile move be allowed?", "Only when it is directly adjacent to the empty space.", "One clear constraint turns a set of images into a real sliding puzzle."),
      gameCheckpoint("Test", "How should the game know the puzzle is solved?", "Compare the current tile order with the intended completed order.", "A defined solved arrangement is safer than relying on visual guesswork.")
    ]
  }, 53),
  createGameProject({
    id: "word-lantern", emoji: "🏮", level: "Polish", title: "Word Lantern", skills: "strings · hints · attempts",
    brief: "Light a lantern by solving a cozy word puzzle. Reveal a few letters, track attempts, and make a wrong guess teach rather than embarrass.",
    outcome: "A hidden word, revealed-letter display, hint, and attempt counter.",
    steps: [
      gameCheckpoint("Plan", "What should Word Lantern store for a round?", "The target word, guessed letters, remaining attempts, and whether the round is over.", "These values are enough to render the puzzle and prevent extra moves after completion."),
      gameCheckpoint("Build", "How should a repeated letter guess behave?", "Explain that it was already tried and do not subtract another attempt.", "Repeated input needs feedback without creating an unfair penalty."),
      gameCheckpoint("Test", "What should the hint do in a beginner version?", "Reveal one useful letter or category clue while clearly showing the tradeoff, if any.", "Helpful hints preserve agency when their effect is visible.")
    ]
  }, 54),
  createGameProject({
    id: "rhythm-raindrops", emoji: "🌧️", level: "Polish", title: "Rhythm Raindrops", skills: "timing · accessibility · feedback",
    brief: "Catch raindrops on the beat with a single key or tap. Add visual timing rings so the game can be enjoyed without sound, and let players pick a comfortable tempo.",
    outcome: "A beat cue, tap judgment, tempo option, and visual-only feedback.",
    steps: [
      gameCheckpoint("Plan", "What makes Rhythm Raindrops accessible from the first build?", "Use a visible beat cue and make sound optional rather than the only timing signal.", "Essential game timing should be perceivable in more than one way."),
      gameCheckpoint("Build", "How should you judge a successful tap?", "Compare the tap time to the nearest beat within a forgiving timing window.", "A timing window makes the game responsive without demanding perfect hardware precision."),
      gameCheckpoint("Test", "What player setting should you test?", "A slower tempo that preserves the same rules and feedback.", "Accessible pace options keep the core game intact while widening who can enjoy it.")
    ]
  }, 55),
  createGameProject({
    id: "two-key-tango", emoji: "🕺", level: "Polish", title: "Two-Key Tango", skills: "two-player · input · fairness",
    brief: "Build a small two-key dance duel on one keyboard. Each player gets an easy-to-reach key, a clear score lane, and a tie outcome that feels celebratory.",
    outcome: "Two keyboard controls, independent scores, and a round result.",
    steps: [
      gameCheckpoint("Plan", "What should Two-Key Tango choose before writing score code?", "Two non-conflicting keys that both players can reach comfortably.", "Physical arrangement is part of fairness in a shared-keyboard game."),
      gameCheckpoint("Build", "How should score updates remain fair?", "Listen for each assigned key and update only that player’s separate score state.", "Independent state prevents one player’s input from changing the other player’s score."),
      gameCheckpoint("Test", "What should happen if both scores end equal?", "Show a tie celebration and offer a rematch without declaring an accidental winner.", "Tie logic matters in every competitive game, especially a friendly one.")
    ]
  }, 56),
  createGameProject({
    id: "save-slot-safari", emoji: "💾", level: "Polish", title: "Save Slot Safari", skills: "local storage · restore · labels",
    brief: "Add a cheerful save slot to a safari collection game. A player should recognize their saved progress, continue safely, and be able to start a new adventure without confusion.",
    outcome: "A named save slot, restore flow, new-game confirmation, and clear status.",
    steps: [
      gameCheckpoint("Plan", "What should Save Slot Safari show before a player presses Continue?", "A short summary of the saved level, score, or collection progress.", "A summary helps someone trust that the slot is the progress they expect."),
      gameCheckpoint("Build", "What should restore code do after reading saved data?", "Validate the expected fields, update state, and render the UI from that restored state.", "Storage is only useful when the app safely recreates a coherent game screen."),
      gameCheckpoint("Test", "What protection belongs before starting a new game?", "Ask for confirmation if it will replace meaningful saved progress.", "A small confirmation makes a potentially destructive action clear and recoverable.")
    ]
  }, 57),
  createGameProject({
    id: "accessi-quest", emoji: "♿", level: "Polish", title: "Accessi-Quest", skills: "keyboard · semantics · motion",
    brief: "Take one earlier mini game and give it an accessibility pass. Make every action keyboard reachable, focus visible, labels understandable, and motion respectful.",
    outcome: "An annotated accessible game screen and a keyboard test checklist.",
    steps: [
      gameCheckpoint("Plan", "What is the best first Accessi-Quest audit?", "List each essential action and the keyboard, visual, and text cue a player receives.", "Mapping the real path exposes gaps more clearly than a decorative checklist."),
      gameCheckpoint("Build", "Which implementation choice gives controls a strong baseline?", "Use semantic buttons or inputs for actions and preserve visible focus styling.", "Native semantics bring useful keyboard behavior and names for assistive technology."),
      gameCheckpoint("Test", "What must a keyboard-only player be able to do?", "Start, play, receive feedback, retry, and reach the game’s result without a mouse.", "Accessible support means the whole core loop works, not merely the opening screen.")
    ]
  }, 58),
  createGameProject({
    id: "pocket-arcade-showcase", emoji: "🏁", level: "Capstone", title: "Pocket Arcade Showcase", skills: "polish · portfolio · reflection",
    brief: "Package your favorite mini game into a friendly showcase. Add a clear title, simple controls, a restart path, a polished empty or loading state if needed, and a short build note.",
    outcome: "A shareable mini-game page with controls, play loop, restart, and project reflection.",
    steps: [
      gameCheckpoint("Plan", "What should Pocket Arcade Showcase prioritize before visual polish?", "A complete player path from title to controls to play to result or restart.", "A portfolio project feels finished when a new person can complete its core loop."),
      gameCheckpoint("Build", "Which detail makes a showcase more welcoming?", "State the game goal and controls in plain language near the start action.", "A small orientation cue lets visitors play without needing you beside them."),
      gameCheckpoint("Test", "What is the most useful final check?", "Ask a fresh player to start, finish or retry, and explain one thing they enjoyed or found unclear.", "A fresh playthrough is the closest thing to a real first impression before sharing.")
    ]
  }, 59)
];

const gameProjectTracks = {
  design: {
    label: "Design Games",
    singular: "design mission",
    description: "Shape the player experience—from color and layout to systems, access, playtests, and a tiny game-jam capstone.",
    projects: designGameProjects
  },
  building: {
    label: "Building Games",
    singular: "build mission",
    description: "Start with one input, grow a game loop, then add rules, feedback, accessibility, saving, and a showcase-ready capstone.",
    projects: buildingGameProjects
  }
};

const challengeItems = [
  { prompt: "Making a page’s button look bright blue", emoji: "🎨", answer: "frontend", feedback: "Yes! Styling and visual design happen on the front-end." },
  { prompt: "Saving a new user’s profile details", emoji: "🗄️", answer: "backend", feedback: "Right — storing information is a back-end/database job." },
  { prompt: "Building a login screen and the code that verifies it", emoji: "🔐", answer: "fullstack", feedback: "Exactly. That feature crosses both sides of the stack." },
  { prompt: "Showing a menu when someone presses an icon", emoji: "🖱️", answer: "frontend", feedback: "Nice call. The interaction happens in the browser." },
  { prompt: "Sending an order from a checkout page to be processed", emoji: "🚚", answer: "fullstack", feedback: "Correct — the front-end sends it and back-end logic processes it." }
];

const promptTask = (task, hint, requirements) => ({ task, hint, requirements });

const aiPromptExercises = {
  html: [
    promptTask("Ask an AI agent to build the structure for a profile card.", "Name HTML and the visible elements you want.", [["HTML", ["html"]], ["a profile card", ["profile card", "profile"]], ["a heading", ["heading", "h1"]], ["a button", ["button"]]]),
    promptTask("Ask an AI agent to create an accessible sign-up form.", "HTML gives the form its structure; labels guide people using it.", [["HTML", ["html"]], ["a form", ["form"]], ["labels", ["label", "labels"]], ["an email field", ["email"]]]),
    promptTask("Ask an AI agent to give a landing page clear semantic sections.", "Think navigation, main content, and the bottom of the page.", [["HTML", ["html"]], ["navigation", ["nav", "navigation"]], ["main content", ["main"]], ["a footer", ["footer"]]])
  ],
  css: [
    promptTask("Ask an AI agent to style a primary Save button.", "CSS controls an element’s visual look.", [["CSS", ["css"]], ["the button", ["button", "save"]], ["a blue color", ["blue", "background", "color"]], ["rounded corners", ["rounded", "corner", "corners", "border radius"]]]),
    promptTask("Ask an AI agent to make a profile card comfortable on phones.", "Use responsive, mobile, or media-query language.", [["CSS", ["css"]], ["the profile card", ["profile", "card"]], ["mobile or responsive behavior", ["mobile", "responsive", "media query"]], ["the layout or screen", ["layout", "screen", "viewport", "phone"]]]),
    promptTask("Ask an AI agent to arrange product cards in a tidy layout.", "CSS Grid or Flexbox are both useful layout tools.", [["CSS", ["css"]], ["a layout tool", ["grid", "flex", "flexbox"]], ["product cards", ["product", "card", "cards"]], ["columns or spacing", ["column", "columns", "gap", "spacing"]]])
  ],
  javascript: [
    promptTask("Ask an AI agent to make a menu react to a click.", "JavaScript handles behavior and events.", [["JavaScript", ["javascript", "js"]], ["the menu", ["menu"]], ["a click or event", ["click", "event", "listener"]], ["opening or toggling", ["open", "toggle", "show", "hide"]]]),
    promptTask("Ask an AI agent to check a sign-up form before it submits.", "Describe the missing detail JavaScript should validate.", [["JavaScript", ["javascript", "js"]], ["the form", ["form", "signup", "sign up"]], ["an email", ["email"]], ["validation", ["validate", "validation", "required", "missing", "check"]]]),
    promptTask("Ask an AI agent to update a cart count after someone adds an item.", "The page should react after a click.", [["JavaScript", ["javascript", "js"]], ["a cart count", ["cart", "count"]], ["a click or button", ["click", "button"]], ["an update", ["update", "increase", "increment", "change"]]])
  ],
  dom: [
    promptTask("Ask an AI agent to change the text in a page heading.", "The DOM lets JavaScript find and change page elements.", [["the DOM", ["dom"]], ["a heading", ["heading", "h1"]], ["text content", ["text", "content", "welcome"]], ["an update", ["change", "update", "replace", "set"]]]),
    promptTask("Ask an AI agent to change a status message after a button press.", "Mention both the click and the DOM update.", [["the DOM", ["dom"]], ["the button or click", ["button", "click"]], ["the message", ["message", "status", "text"]], ["an update", ["change", "update", "replace", "set"]]]),
    promptTask("Ask an AI agent to add a new task to a visible task list.", "The agent needs to create an element and put it into the page.", [["the DOM", ["dom"]], ["a task list", ["task", "list", "item"]], ["creating an element", ["create", "new", "element", "item"]], ["adding it to the page", ["append", "add", "insert"]]])
  ],
  frontend: [
    promptTask("Ask an AI agent to build the visible part of a product feature.", "Front-end means what someone sees and uses in the browser.", [["front-end", ["front end", "frontend"]], ["a product card", ["product", "card"]], ["an image", ["image"]], ["a price", ["price"]], ["a button", ["button", "cart"]]]),
    promptTask("Ask an AI agent to improve a visible login experience.", "Ask for UI elements a person can see and use.", [["front-end", ["front end", "frontend"]], ["a login form", ["login", "sign in", "form"]], ["labels", ["label", "labels"]], ["helpful feedback", ["error", "message", "feedback"]], ["a button", ["button"]]]),
    promptTask("Ask an AI agent to make a navigation bar friendlier on a phone.", "This is a browser-facing front-end change.", [["front-end", ["front end", "frontend"]], ["navigation", ["nav", "navigation", "menu"]], ["mobile behavior", ["mobile", "responsive", "phone"]], ["the screen or layout", ["screen", "layout", "browser"]]])
  ],
  server: [
    promptTask("Ask an AI agent to make a server route for a user profile.", "A server receives a request and sends back a response.", [["a server", ["server"]], ["a route", ["route", "endpoint"]], ["a profile", ["profile", "user"]], ["a JSON response", ["json", "response", "return", "send"]]]),
    promptTask("Ask an AI agent to check a login on the server.", "The server should check account information, not only the visible form.", [["a server", ["server"]], ["a login", ["login", "sign in", "authentication"]], ["a check", ["check", "validate", "verify"]], ["user information", ["user", "account", "database"]]]),
    promptTask("Ask an AI agent to process a checkout request on a server.", "Mention the incoming request and the answer sent back.", [["a server", ["server"]], ["checkout or an order", ["checkout", "order"]], ["a total", ["total", "calculate"]], ["a response", ["response", "return", "send", "json"]]])
  ],
  database: [
    promptTask("Ask an AI agent to design storage for a task app.", "Say which details the database needs to remember.", [["a database", ["database", "db"]], ["tasks", ["task", "tasks"]], ["a table or schema", ["table", "schema", "column"]], ["a title", ["title"]], ["a status", ["status", "complete", "completion"]]]),
    promptTask("Ask an AI agent to save a profile after sign-up.", "Databases remember information after someone leaves the page.", [["a database", ["database", "db"]], ["a user profile", ["user", "profile"]], ["saving", ["save", "store", "insert"]], ["sign-up", ["signup", "sign up"]]]),
    promptTask("Ask an AI agent to retrieve tasks that were already saved.", "A SQL query is one way to ask a database for information.", [["a database", ["database", "db"]], ["tasks", ["task", "tasks"]], ["a query", ["sql", "select", "query"]], ["retrieving", ["retrieve", "fetch", "get", "find"]]])
  ],
  api: [
    promptTask("Ask an AI agent to create a way for the app to get saved tasks.", "An API endpoint is a doorway for requesting data.", [["an API", ["api"]], ["an endpoint", ["endpoint", "route"]], ["tasks", ["task", "tasks"]], ["returning data", ["return", "send", "get", "fetch"]]]),
    promptTask("Ask an AI agent how the browser should load a profile.", "The front-end can call an API with a request.", [["an API", ["api"]], ["the browser or front-end", ["browser", "front end", "frontend", "client"]], ["calling or fetching", ["call", "fetch", "request"]], ["a profile", ["profile"]]]),
    promptTask("Ask an AI agent to document a missing-task API result.", "A useful API response includes an error status and clear information.", [["an API", ["api"]], ["a response", ["response"]], ["a task", ["task", "tasks"]], ["an error status", ["404", "error", "not found", "missing"]], ["a helpful message", ["message", "helpful"]]])
  ],
  authentication: [
    promptTask("Ask an AI agent to make a login form verify who someone is.", "Authentication answers “Are you really you?”", [["authentication", ["authentication", "authenticate"]], ["a login", ["login", "sign in", "log in"]], ["a verification", ["verify", "check", "confirm"]], ["a user identity", ["identity", "user"]]]),
    promptTask("Ask an AI agent to protect a private profile route.", "Only a signed-in person should be allowed through.", [["authentication", ["authentication", "authenticate"]], ["a profile", ["profile"]], ["a route or API", ["route", "api", "endpoint"]], ["protection", ["protect", "secure", "only"]], ["being signed in", ["signed in", "logged in", "login"]]]),
    promptTask("Ask an AI agent to handle passwords safely during sign-in.", "Authentication should verify a password without storing it as plain text.", [["authentication", ["authentication", "authenticate"]], ["passwords", ["password", "passwords"]], ["the server", ["server", "backend", "back end"]], ["safe hashing", ["hash", "secure"]]])
  ],
  backend: [
    promptTask("Ask an AI agent to handle the work behind a checkout screen.", "Back-end work handles data and business rules away from the visible page.", [["back-end", ["backend", "back end"]], ["an order", ["order", "cart", "checkout"]], ["a total", ["total", "calculate"]], ["saving data", ["save", "store", "database"]]]),
    promptTask("Ask an AI agent to save a contact-form submission.", "The form is front-end; saving it is back-end work.", [["back-end", ["backend", "back end"]], ["a contact form", ["contact", "form", "submission"]], ["a route or API", ["route", "api", "endpoint"]], ["saving", ["save", "store"]]]),
    promptTask("Ask an AI agent what happens after checkout data leaves the screen.", "Connect the front-end request to the work on the back-end.", [["back-end", ["backend", "back end"]], ["the front-end", ["front end", "frontend", "browser", "client"]], ["a checkout request", ["checkout", "order", "request"]], ["sending", ["send", "sends", "request"]]])
  ],
  "request-response": [
    promptTask("Ask an AI agent to explain a profile-loading trip.", "One side asks; the other side answers.", [["a request", ["request"]], ["a response", ["response"]], ["the browser or front-end", ["browser", "front end", "frontend", "client"]], ["a server or API", ["server", "api"]], ["a profile", ["profile", "user"]]]),
    promptTask("Ask an AI agent to make an endpoint receive and return information.", "An API can receive a request and return a JSON response.", [["a request", ["request"]], ["a response", ["response"]], ["an endpoint", ["api", "endpoint", "route"]], ["JSON data", ["json", "data"]], ["tasks", ["task", "tasks"]]]),
    promptTask("Ask an AI agent to give people a helpful result when loading tasks fails.", "A failed request should still receive a clear response.", [["a request", ["request"]], ["a response", ["response"]], ["tasks", ["task", "tasks"]], ["an error", ["error", "fail", "failed"]], ["a helpful message", ["friendly", "helpful", "message"]]])
  ],
  fullstack: [
    promptTask("Ask an AI agent to plan a complete task feature.", "Full-stack work connects a screen to the systems behind it.", [["full-stack", ["full stack", "fullstack"]], ["the front-end", ["front end", "frontend"]], ["the back-end", ["back end", "backend"]], ["a task form", ["task", "form"]], ["saving", ["save", "store", "database"]]]),
    promptTask("Ask an AI agent to build a complete sign-up flow.", "Name the visible screen, the API, and the place that stores the account.", [["full-stack", ["full stack", "fullstack"]], ["sign-up", ["signup", "sign up", "login"]], ["an API", ["api"]], ["a database", ["database", "db"]], ["a screen or UI", ["screen", "ui", "front end", "frontend"]]]),
    promptTask("Ask an AI agent to trace a new order from checkout to confirmation.", "A full-stack feature crosses the page, server, and answer back to a person.", [["full-stack", ["full stack", "fullstack"]], ["an order", ["order", "checkout"]], ["the page or front-end", ["page", "front end", "frontend", "browser"]], ["the server", ["server", "backend", "back end"]], ["a response", ["response", "return", "confirm", "back"]]])
  ]
};

const cardProgressStorageKey = "stacksprint-card-progress-v3";
const gameLabStorageKey = "stacksprint-game-project-lab-v1";

function loadCardProgress() {
  try {
    const saved = JSON.parse(localStorage.getItem(cardProgressStorageKey) || "{}");
    return saved && typeof saved === "object" ? saved : {};
  } catch {
    return {};
  }
}

function freshGameTrackProgress(trackKey) {
  return {
    current: 0,
    steps: Array(gameProjectTracks[trackKey].projects.length).fill(0)
  };
}

function loadGameLabProgress() {
  const fallback = {
    design: freshGameTrackProgress("design"),
    building: freshGameTrackProgress("building")
  };
  try {
    const saved = JSON.parse(localStorage.getItem(gameLabStorageKey) || "{}");
    if (!saved || typeof saved !== "object") return fallback;
    Object.keys(fallback).forEach((trackKey) => {
      const projectCount = gameProjectTracks[trackKey].projects.length;
      const candidate = saved[trackKey] || {};
      fallback[trackKey].current = Math.max(0, Math.min(Number(candidate.current) || 0, projectCount - 1));
      if (Array.isArray(candidate.steps)) {
        fallback[trackKey].steps = fallback[trackKey].steps.map((_, index) => Math.max(0, Math.min(3, Number(candidate.steps[index]) || 0)));
      }
      while (fallback[trackKey].current < projectCount - 1 && fallback[trackKey].steps[fallback[trackKey].current] >= 3) {
        fallback[trackKey].current += 1;
      }
    });
    return fallback;
  } catch {
    return fallback;
  }
}

function persistGameLabProgress() {
  localStorage.setItem(gameLabStorageKey, JSON.stringify(state.gameLabProgress));
}

const state = {
  filter: "all",
  cardIndex: 0,
  revealed: false,
  cardProgress: loadCardProgress(),
  mode: "study",
  knownIds: new Set(JSON.parse(localStorage.getItem("stacksprint-known") || "[]")),
  quizIndex: 0,
  quizScore: 0,
  quizAnswered: false,
  quizStarted: false,
  cyberVocabRevealed: new Set(),
  cyberQuizIndex: 0,
  cyberQuizScore: 0,
  cyberQuizAnswered: false,
  gameTrack: "design",
  gameLabProgress: loadGameLabProgress(),
  gameCheckpointAnswered: false,
  challengeIndex: 0,
  challengeScore: 0,
  challengeAnswered: false
};

const el = (id) => document.getElementById(id);
const flashcard = el("flashcard");
const cardFront = el("cardFront");
const cardBack = el("cardBack");
const cardCounter = el("cardCounter");
const cardHint = el("cardHint");
const flipButtonText = el("flipButtonText");
const flipButtonIcon = el("flipButtonIcon");
const syntaxPractice = el("syntaxPractice");
const readCodePrompt = el("readCodePrompt");
const readCodeButton = el("readCode");
const readCodeButtonText = el("readCodeButtonText");
const practiceCode = el("practiceCode");
const codeInput = el("codeInput");
const typingFeedback = el("typingFeedback");
const checkTyping = el("checkTyping");
const confidenceLabel = el("confidenceLabel");
const promptPractice = el("promptPractice");
const promptDots = el("promptDots");
const promptProgressText = el("promptProgressText");
const promptExercise = el("promptExercise");
const promptSuccess = el("promptSuccess");
const promptNumber = el("promptNumber");
const promptTaskText = el("promptTaskText");
const promptHint = el("promptHint");
const promptIngredients = el("promptIngredients");
const aiPromptInput = el("aiPromptInput");
const promptFeedback = el("promptFeedback");
const checkPrompt = el("checkPrompt");
const nextCard = el("nextCard");
const progressText = el("progressText");
const progressBar = el("progressBar");
const progressMessage = el("progressMessage");
const toast = el("toast");
const cyberVocabGrid = el("cyberVocabGrid");
const cyberQuiz = el("cyberQuiz");
const gameProjectMission = el("gameProjectMission");
const gameProjectMap = el("gameProjectMap");
const gameTrackProgress = el("gameTrackProgress");
const gameRouteCopy = el("gameRouteCopy");
let toastTimer;

function topicLabel(topic) {
  return { frontend: "Front-end", backend: "Back-end", fullstack: "Full-stack" }[topic] || "All cards";
}

function filteredCards() {
  return state.filter === "all" ? cards : cards.filter((card) => card.category === state.filter);
}

function currentCard() {
  const items = filteredCards();
  state.cardIndex = Math.max(0, Math.min(state.cardIndex, items.length - 1));
  return items[state.cardIndex];
}

function renderProgress() {
  const known = state.knownIds.size;
  const percent = Math.round((known / cards.length) * 100);
  progressText.textContent = known;
  progressBar.style.width = `${percent}%`;
  if (known === 0) progressMessage.textContent = "A few quick cards and you’ll speak web.";
  else if (known < 5) progressMessage.textContent = "You’re building useful web instincts.";
  else if (known < 12) progressMessage.textContent = "Nice — the stack is starting to connect.";
  else progressMessage.textContent = "Deck complete. You can explain the web!";
}

function makeCardProgress() {
  return { read: false, typed: false, codeDraft: "", promptDone: [false, false, false], promptDrafts: ["", "", ""] };
}

function progressFor(cardId = currentCard().id) {
  if (!state.cardProgress[cardId] || typeof state.cardProgress[cardId] !== "object") {
    state.cardProgress[cardId] = makeCardProgress();
  }
  const progress = state.cardProgress[cardId];
  progress.read = Boolean(progress.read);
  progress.typed = Boolean(progress.typed);
  progress.codeDraft = typeof progress.codeDraft === "string" ? progress.codeDraft : "";
  progress.promptDone = Array.isArray(progress.promptDone) ? progress.promptDone.map(Boolean).slice(0, 3) : [false, false, false];
  progress.promptDrafts = Array.isArray(progress.promptDrafts) ? progress.promptDrafts.map((draft) => String(draft || "")).slice(0, 3) : ["", "", ""];
  while (progress.promptDone.length < 3) progress.promptDone.push(false);
  while (progress.promptDrafts.length < 3) progress.promptDrafts.push("");
  return progress;
}

function persistCardProgress() {
  localStorage.setItem(cardProgressStorageKey, JSON.stringify(state.cardProgress));
}

function normalizeCode(value) {
  return value.trim().replace(/\s+/g, " ");
}

function normalizePrompt(value) {
  return ` ${value.toLowerCase().replace(/[^a-z0-9]+/g, " ").replace(/\s+/g, " ").trim()} `;
}

function includesPhrase(prompt, phrase) {
  return normalizePrompt(prompt).includes(` ${normalizePrompt(phrase).trim()} `);
}

function describeCharacter(character) {
  if (character === " ") return "a space";
  if (character === "\"") return "a quotation mark";
  if (character === "'") return "an apostrophe";
  if (character === ";") return "a semicolon";
  if (character === "(") return "an opening parenthesis";
  if (character === ")") return "a closing parenthesis";
  return `“${character}”`;
}

function promptActionIncluded(value) {
  return ["add", "build", "create", "write", "use", "make", "update", "show", "explain", "plan", "implement", "style", "design", "save", "store", "return", "send", "retrieve", "protect", "verify"].some((word) => includesPhrase(value, word));
}

function practiceReady(card = currentCard()) {
  const progress = progressFor(card.id);
  return state.revealed && progress.read && progress.typed;
}

function promptsComplete(card = currentCard()) {
  return progressFor(card.id).promptDone.every(Boolean);
}

function cardChecklistComplete(card = currentCard()) {
  const progress = progressFor(card.id);
  return progress.read && progress.typed && progress.promptDone.every(Boolean);
}

function isLastCardInView() {
  return state.cardIndex >= filteredCards().length - 1;
}

function updateNavigationControls() {
  const complete = state.revealed && cardChecklistComplete();
  const previousCard = el("previousCard");
  previousCard.disabled = state.cardIndex === 0;
  nextCard.disabled = !complete || isLastCardInView();
  nextCard.setAttribute("aria-label", nextCard.disabled
    ? (isLastCardInView() && complete ? "You completed this study path" : "Complete three AI prompts to unlock the next card")
    : "Next card");
}

function updateConfidenceButtons() {
  const card = currentCard();
  const complete = state.revealed && cardChecklistComplete(card);
  document.querySelectorAll(".confidence-button").forEach((button) => {
    button.disabled = !complete;
  });

  const progress = progressFor(card.id);
  if (!state.revealed) confidenceLabel.textContent = "Flip the card to start its two-step checkpoint.";
  else if (!progress.read) confidenceLabel.textContent = "Read the mini code line aloud, then type it once.";
  else if (!progress.typed) confidenceLabel.textContent = "Nice reading — type the line to begin the AI prompt lab.";
  else if (!promptsComplete(card)) confidenceLabel.textContent = "Complete all 3 AI prompts to unlock this card.";
  else confidenceLabel.textContent = "All checkpoints complete. How’d that feel?";
}

function updatePracticePanel(card) {
  syntaxPractice.hidden = !state.revealed;
  if (!state.revealed) return;

  const progress = progressFor(card.id);
  practiceCode.textContent = card.code;
  readCodePrompt.innerHTML = card.readAloud;
  readCodeButton.classList.toggle("is-read", progress.read);
  readCodeButton.disabled = progress.read;
  readCodeButton.setAttribute("aria-pressed", String(progress.read));
  readCodeButtonText.textContent = progress.read ? "Read aloud ✓" : "I read it aloud";
  codeInput.placeholder = `Type ${card.term} code here…`;
  codeInput.value = progress.codeDraft;
  codeInput.readOnly = progress.typed;
  codeInput.removeAttribute("aria-invalid");
  codeInput.closest(".typing-field").classList.toggle("is-correct", progress.typed);
  codeInput.closest(".typing-field").classList.remove("is-incorrect");
  typingFeedback.textContent = progress.typed ? "✓ Good code reading. Now complete 3 AI prompts." : "Write the line, then check your typing.";
  typingFeedback.className = progress.typed ? "good" : "";
  checkTyping.disabled = progress.typed || !codeInput.value.trim();
}

function updateTypingState() {
  const card = currentCard();
  const progress = progressFor(card.id);
  if (progress.typed) return;
  progress.codeDraft = codeInput.value;
  persistCardProgress();
  const field = codeInput.closest(".typing-field");
  field.classList.remove("is-correct", "is-incorrect");
  codeInput.removeAttribute("aria-invalid");
  typingFeedback.textContent = "Write the line, then check your typing.";
  typingFeedback.className = "";
  checkTyping.disabled = !codeInput.value.trim();
}

function validateTyping() {
  const card = currentCard();
  const progress = progressFor(card.id);
  if (!state.revealed || progress.typed || !codeInput.value.trim()) return;
  progress.codeDraft = codeInput.value;
  const expected = normalizeCode(card.code);
  const answer = normalizeCode(codeInput.value);
  const field = codeInput.closest(".typing-field");

  if (answer === expected) {
    progress.typed = true;
    persistCardProgress();
    field.classList.remove("is-incorrect");
    field.classList.add("is-correct");
    codeInput.readOnly = true;
    codeInput.setAttribute("aria-invalid", "false");
    typingFeedback.textContent = "✓ Good code reading. Now complete 3 AI prompts.";
    typingFeedback.className = "good";
    checkTyping.disabled = true;
    popSparkles(checkTyping);
    renderPromptPractice(card);
  } else {
    const mismatchAt = [...answer].findIndex((character, index) => character !== expected[index]);
    const expectedCharacter = expected[mismatchAt === -1 ? expected.length : mismatchAt];
    field.classList.remove("is-correct");
    field.classList.add("is-incorrect");
    codeInput.setAttribute("aria-invalid", "true");
    typingFeedback.textContent = expectedCharacter
      ? `Almost — check ${describeCharacter(expectedCharacter)} near the first difference.`
      : "Almost — check for an extra character at the end.";
    typingFeedback.className = "bad";
  }
  updateNavigationControls();
  updateConfidenceButtons();
}

function toggleReadCode() {
  if (!state.revealed) return;
  const card = currentCard();
  const progress = progressFor(card.id);
  if (progress.read) return;
  progress.read = true;
  persistCardProgress();
  updatePracticePanel(card);
  renderPromptPractice(card);
  updateNavigationControls();
  updateConfidenceButtons();
}

function renderPromptPractice(card = currentCard()) {
  promptPractice.hidden = !practiceReady(card);
  if (!practiceReady(card)) return;

  const exercises = aiPromptExercises[card.id];
  const progress = progressFor(card.id);
  const completedCount = progress.promptDone.filter(Boolean).length;
  promptDots.innerHTML = progress.promptDone.map((done, index) => `<span class="prompt-dot ${done ? "is-done" : ""}">${done ? "✓" : index + 1}</span>`).join("");
  promptDots.setAttribute("aria-label", `${completedCount} of 3 prompts completed`);
  promptProgressText.textContent = `${completedCount} / 3 clear prompts`;

  const promptIndex = progress.promptDone.findIndex((done) => !done);
  if (promptIndex === -1) {
    promptExercise.hidden = true;
    promptSuccess.hidden = false;
    return;
  }

  const exercise = exercises[promptIndex];
  promptExercise.hidden = false;
  promptSuccess.hidden = true;
  promptNumber.textContent = `Prompt ${promptIndex + 1} of 3`;
  promptTaskText.textContent = exercise.task;
  promptHint.textContent = exercise.hint;
  promptIngredients.innerHTML = exercise.requirements.map(([label]) => `<li>${label}</li>`).join("");
  aiPromptInput.value = progress.promptDrafts[promptIndex];
  aiPromptInput.classList.remove("is-incorrect");
  aiPromptInput.removeAttribute("aria-invalid");
  promptFeedback.textContent = "Use the term accurately and be specific about the result you want.";
  promptFeedback.className = "";
  checkPrompt.disabled = !aiPromptInput.value.trim();
}

function updatePromptDraft() {
  if (!practiceReady()) return;
  const card = currentCard();
  const progress = progressFor(card.id);
  const promptIndex = progress.promptDone.findIndex((done) => !done);
  if (promptIndex === -1) return;
  progress.promptDrafts[promptIndex] = aiPromptInput.value;
  persistCardProgress();
  aiPromptInput.classList.remove("is-incorrect");
  aiPromptInput.removeAttribute("aria-invalid");
  promptFeedback.textContent = "Use the term accurately and be specific about the result you want.";
  promptFeedback.className = "";
  checkPrompt.disabled = !aiPromptInput.value.trim();
}

function formatMissingIngredients(missing) {
  if (missing.length === 1) return missing[0];
  if (missing.length === 2) return `${missing[0]} and ${missing[1]}`;
  return `${missing.slice(0, 2).join(", ")}, and ${missing[2]}`;
}

function validateAiPrompt() {
  if (!practiceReady() || !aiPromptInput.value.trim()) return;
  const card = currentCard();
  const progress = progressFor(card.id);
  const promptIndex = progress.promptDone.findIndex((done) => !done);
  if (promptIndex === -1) return;
  const exercise = aiPromptExercises[card.id][promptIndex];
  const draft = aiPromptInput.value.trim();
  progress.promptDrafts[promptIndex] = draft;
  const missing = exercise.requirements
    .filter(([, aliases]) => !aliases.some((alias) => includesPhrase(draft, alias)))
    .map(([label]) => label);
  if (!promptActionIncluded(draft)) missing.unshift("a clear action");

  if (missing.length) {
    persistCardProgress();
    aiPromptInput.classList.add("is-incorrect");
    aiPromptInput.setAttribute("aria-invalid", "true");
    promptFeedback.textContent = `Almost. Add ${formatMissingIngredients(missing)} and try again.`;
    promptFeedback.className = "bad";
    return;
  }

  progress.promptDone[promptIndex] = true;
  persistCardProgress();
  popSparkles(checkPrompt);
  showToast(promptIndex === 2 ? "Three clear AI prompts complete — next card unlocked." : `Prompt ${promptIndex + 1} is clear. Keep going!`);
  renderPromptPractice(card);
  updateNavigationControls();
  updateConfidenceButtons();
}

function renderCard() {
  const card = currentCard();
  const items = filteredCards();
  const progress = progressFor(card.id);
  const categoryEmoji = { frontend: "◒", backend: "◈", fullstack: "⧉" }[card.category];
  flashcard.dataset.tone = card.category;
  flashcard.classList.toggle("is-flipped", state.revealed);
  flashcard.setAttribute("aria-label", state.revealed ? `Hide answer for ${card.term}` : `Reveal answer for ${card.term}`);
  cardFront.innerHTML = `
    <span class="card-category"><span>${categoryEmoji}</span>${card.categoryLabel}</span>
    <span class="card-term">${card.term}</span>
    <span class="card-clue">${card.clue}</span>
    <span class="flip-cue"><b>↻</b> Tap to flip</span>
  `;
  cardBack.innerHTML = `
    <span class="card-back-category">${topicLabel(card.category)} · plain English</span>
    <span class="answer-title">${card.term}</span>
    <span class="answer-definition">${card.definition}</span>
    <span class="answer-example"><b>For example:</b> ${card.example}</span>
  `;
  cardCounter.textContent = `${String(state.cardIndex + 1).padStart(2, "0")} / ${String(items.length).padStart(2, "0")}`;
  if (!state.revealed) cardHint.innerHTML = "Press <kbd>Space</kbd> to reveal";
  else if (!progress.read || !progress.typed) cardHint.innerHTML = "Read + type the code to start the prompt lab";
  else if (!promptsComplete(card)) cardHint.innerHTML = "Complete 3 AI prompts to unlock the next card";
  else if (isLastCardInView()) cardHint.textContent = "This study path is complete ✦";
  else cardHint.innerHTML = "Next card unlocked · press <kbd>→</kbd>";
  flipButtonText.textContent = state.revealed ? "Hide answer" : "Reveal answer";
  flipButtonIcon.textContent = state.revealed ? "↻" : "✦";
  updatePracticePanel(card);
  renderPromptPractice(card);
  updateNavigationControls();
  updateConfidenceButtons();
}

function flipCard() {
  state.revealed = !state.revealed;
  renderCard();
}

function goToCard(delta) {
  const items = filteredCards();
  if (delta > 0 && !cardChecklistComplete()) {
    showToast("Finish all 3 AI prompts to unlock the next flash card.");
    return false;
  }
  if (delta > 0 && state.cardIndex >= items.length - 1) {
    showToast("You’ve finished this study path — nice work!");
    return false;
  }
  if (delta < 0 && state.cardIndex === 0) return false;
  state.cardIndex = Math.max(0, Math.min(items.length - 1, state.cardIndex + delta));
  state.revealed = false;
  renderCard();
  return true;
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("is-visible");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 2300);
}

function popSparkles(origin) {
  const layer = el("sparkleLayer");
  const rect = origin.getBoundingClientRect();
  for (let i = 0; i < 8; i += 1) {
    const spark = document.createElement("span");
    spark.className = "sparkle";
    spark.textContent = i % 2 ? "✦" : "·";
    spark.style.left = `${rect.left + rect.width / 2}px`;
    spark.style.top = `${rect.top + rect.height / 2}px`;
    spark.style.setProperty("--sparkle-x", `${(Math.random() - .5) * 130}px`);
    spark.style.setProperty("--sparkle-y", `${-30 - Math.random() * 100}px`);
    layer.appendChild(spark);
    setTimeout(() => spark.remove(), 800);
  }
}

function rateCard(confidence, button) {
  if (!state.revealed || !cardChecklistComplete()) {
    showToast("Complete the AI prompt lab before finishing this card.");
    return;
  }
  const card = currentCard();
  if (confidence === "nailed") {
    const isNew = !state.knownIds.has(card.id);
    state.knownIds.add(card.id);
    localStorage.setItem("stacksprint-known", JSON.stringify([...state.knownIds]));
    renderProgress();
    popSparkles(button);
    showToast(isNew ? `Nice! ${card.term} is in your “I know it” pile.` : `Still sharp — ${card.term} stays locked in.`);
  } else if (confidence === "almost") {
    showToast("Almost is excellent. One more pass and it’ll stick.");
  } else {
    showToast("No sweat — this one will circle back soon.");
  }
  if (!isLastCardInView()) setTimeout(() => goToCard(1), 300);
}

function canJumpToCard(target) {
  const currentPosition = cards.indexOf(currentCard());
  const targetPosition = cards.indexOf(target);
  if (targetPosition <= currentPosition || cardChecklistComplete()) return true;
  showToast("Finish this card’s 3 AI prompts before jumping ahead.");
  return false;
}

function navigateToCard(target, filter = "all") {
  if (!target || !canJumpToCard(target)) return false;
  state.filter = filter;
  state.cardIndex = filteredCards().indexOf(target);
  state.revealed = false;
  document.querySelectorAll(".filter-chip").forEach((button) => {
    const selected = button.dataset.filter === filter;
    button.classList.toggle("is-active", selected);
    button.setAttribute("aria-selected", String(selected));
  });
  renderCard();
  return true;
}

function setFilter(filter) {
  const target = filter === "all" ? cards[0] : cards.find((card) => card.category === filter);
  if (!navigateToCard(target, filter)) return false;
  showToast(filter === "all" ? "All 12 cards are ready." : `${topicLabel(filter)} cards are on deck.`);
  return true;
}

function setMode(mode) {
  state.mode = mode;
  const isStudy = mode === "study";
  el("studyView").hidden = !isStudy;
  el("quizView").hidden = isStudy;
  document.querySelectorAll(".mode-button").forEach((button) => {
    const selected = button.dataset.mode === mode;
    button.classList.toggle("is-active", selected);
    button.setAttribute("aria-selected", String(selected));
  });
  if (!isStudy && !state.quizStarted) {
    state.quizStarted = true;
    renderQuiz();
  }
}

function renderQuiz() {
  const quizView = el("quizView");
  if (state.quizIndex >= quizQuestions.length) {
    const score = state.quizScore;
    const percent = Math.round((score / quizQuestions.length) * 100);
    quizView.innerHTML = `
      <div class="quiz-summary">
        <span class="summary-spark">✦</span>
        <h3>${percent >= 80 ? "Stack status: strong" : "Great reps!"}</h3>
        <p>You got <strong>${score} of ${quizQuestions.length}</strong> right. ${percent >= 80 ? "You can already tell the screen from the systems behind it." : "A quick card pass will make these ideas click even faster."}</p>
        <button class="restart-quiz" id="restartQuiz" type="button">Run it again</button>
      </div>
    `;
    el("restartQuiz").addEventListener("click", () => {
      state.quizIndex = 0;
      state.quizScore = 0;
      state.quizAnswered = false;
      state.quizStarted = true;
      quizView.innerHTML = `
        <div class="quiz-header"><div><p class="eyebrow muted-eyebrow">25-question skills check</p><h3 id="quizTitle">Can you apply it?</h3></div><span class="quiz-count" id="quizCounter">1 / ${quizQuestions.length}</span></div>
        <div class="quiz-meter"><span id="quizProgress"></span></div>
        <p class="quiz-question" id="quizQuestion"></p><div class="answer-list" id="answerList"></div>
        <div class="quiz-footer"><p id="quizFeedback" class="quiz-feedback" aria-live="polite">Pick the answer that feels most true.</p><button class="next-question" id="nextQuestion" type="button" disabled>Next question <span>→</span></button></div>
      `;
      renderQuiz();
    });
    return;
  }
  const question = quizQuestions[state.quizIndex];
  el("quizCounter").textContent = `${state.quizIndex + 1} / ${quizQuestions.length}`;
  const completedCount = state.quizIndex + (state.quizAnswered ? 1 : 0);
  el("quizProgress").style.width = `${(completedCount / quizQuestions.length) * 100}%`;
  el("quizQuestion").textContent = question.question;
  el("quizFeedback").textContent = "Pick the answer that feels most true.";
  el("quizFeedback").className = "quiz-feedback";
  const list = el("answerList");
  list.innerHTML = question.choices.map((choice, index) => `
    <button class="answer-choice" type="button" data-answer="${index}">
      <span class="answer-choice-letter">${String.fromCharCode(65 + index)}</span>${choice}
    </button>
  `).join("");
  el("nextQuestion").disabled = true;
  el("nextQuestion").textContent = state.quizIndex === quizQuestions.length - 1 ? "See results →" : "Next question →";
  list.querySelectorAll(".answer-choice").forEach((button) => {
    button.addEventListener("click", () => answerQuiz(Number(button.dataset.answer)));
  });
  el("nextQuestion").addEventListener("click", nextQuizQuestion, { once: true });
}

function answerQuiz(index) {
  if (state.quizAnswered) return;
  state.quizAnswered = true;
  const question = quizQuestions[state.quizIndex];
  const correct = index === question.answer;
  if (correct) state.quizScore += 1;
  document.querySelectorAll(".answer-choice").forEach((button) => {
    const option = Number(button.dataset.answer);
    button.disabled = true;
    if (option === question.answer) button.classList.add("correct");
    else if (option === index) button.classList.add("incorrect");
  });
  const feedback = el("quizFeedback");
  feedback.textContent = correct ? question.explanation : `Not quite. ${question.explanation}`;
  feedback.classList.add(correct ? "good" : "bad");
  el("quizProgress").style.width = `${((state.quizIndex + 1) / quizQuestions.length) * 100}%`;
  el("nextQuestion").disabled = false;
  if (correct) popSparkles(el("answerList"));
}

function nextQuizQuestion() {
  if (!state.quizAnswered) return;
  state.quizIndex += 1;
  state.quizAnswered = false;
  renderQuiz();
}

function renderCyberVocab() {
  cyberVocabGrid.innerHTML = cyberTerms.map((term, index) => `
    <button class="cyber-vocab-card" type="button" data-cyber-term="${term.id}" aria-expanded="false">
      <span class="cyber-vocab-number">${String(index + 1).padStart(2, "0")}</span>
      <span class="cyber-vocab-term">${term.term}</span>
      <span class="cyber-vocab-clue">${term.clue}</span>
      <span class="cyber-vocab-definition" hidden>${term.definition}</span>
      <span class="cyber-vocab-flip">Tap to reveal →</span>
    </button>
  `).join("");

  cyberVocabGrid.querySelectorAll(".cyber-vocab-card").forEach((button) => {
    button.addEventListener("click", () => {
      const termId = button.dataset.cyberTerm;
      const revealed = !state.cyberVocabRevealed.has(termId);
      if (revealed) state.cyberVocabRevealed.add(termId);
      else state.cyberVocabRevealed.delete(termId);
      button.classList.toggle("is-revealed", revealed);
      button.setAttribute("aria-expanded", String(revealed));
      button.querySelector(".cyber-vocab-definition").hidden = !revealed;
      button.querySelector(".cyber-vocab-flip").textContent = revealed ? "Tap to hide ↑" : "Tap to reveal →";
    });
  });
}

function cyberQuizMarkup() {
  return `
    <div class="cyber-quiz-header">
      <div>
        <p class="eyebrow muted-eyebrow">Final checkpoint</p>
        <h3 id="cyber-quiz-title">Can you spot the safer move?</h3>
      </div>
      <span class="quiz-count" id="cyberQuizCounter">1 / ${cyberQuizQuestions.length}</span>
    </div>
    <div class="quiz-meter cyber-quiz-meter"><span id="cyberQuizProgress"></span></div>
    <p class="cyber-quiz-question" id="cyberQuizQuestion"></p>
    <div class="cyber-answer-list" id="cyberAnswerList"></div>
    <div class="cyber-quiz-footer">
      <p id="cyberQuizFeedback" class="quiz-feedback" aria-live="polite">Choose the answer that keeps people and information safer.</p>
      <button class="next-question cyber-next-question" id="cyberNextQuestion" type="button" disabled>Next question <span>→</span></button>
    </div>
  `;
}

function renderCyberQuiz() {
  if (state.cyberQuizIndex >= cyberQuizQuestions.length) {
    const score = state.cyberQuizScore;
    const percent = Math.round((score / cyberQuizQuestions.length) * 100);
    cyberQuiz.innerHTML = `
      <div class="cyber-summary" aria-live="polite">
        <span class="summary-spark" aria-hidden="true">✦</span>
        <h3 id="cyber-quiz-title">Course complete — you finished the Cybersecurity Mini Course!</h3>
        <p>You got <strong>${score} of ${cyberQuizQuestions.length}</strong> right (${percent}%). ${percent >= 80 ? "Your safety vocabulary is looking strong." : "Nice work — replay it whenever you want another safety rep."}</p>
        <button class="restart-cyber-quiz" id="restartCyberQuiz" type="button">Practice again</button>
      </div>
    `;
    el("restartCyberQuiz").addEventListener("click", () => {
      state.cyberQuizIndex = 0;
      state.cyberQuizScore = 0;
      state.cyberQuizAnswered = false;
      cyberQuiz.innerHTML = cyberQuizMarkup();
      renderCyberQuiz();
    });
    return;
  }

  const question = cyberQuizQuestions[state.cyberQuizIndex];
  const counter = el("cyberQuizCounter");
  const progress = el("cyberQuizProgress");
  const questionText = el("cyberQuizQuestion");
  const answerList = el("cyberAnswerList");
  const feedback = el("cyberQuizFeedback");
  const nextButton = el("cyberNextQuestion");
  counter.textContent = `${state.cyberQuizIndex + 1} / ${cyberQuizQuestions.length}`;
  const completedCount = state.cyberQuizIndex + (state.cyberQuizAnswered ? 1 : 0);
  progress.style.width = `${(completedCount / cyberQuizQuestions.length) * 100}%`;
  questionText.textContent = question.question;
  feedback.textContent = "Choose the answer that keeps people and information safer.";
  feedback.className = "quiz-feedback";
  answerList.innerHTML = question.choices.map((choice, index) => `
    <button class="cyber-answer-choice" type="button" data-cyber-answer="${index}">
      <span class="answer-choice-letter">${String.fromCharCode(65 + index)}</span>${choice}
    </button>
  `).join("");
  nextButton.disabled = true;
  nextButton.textContent = state.cyberQuizIndex === cyberQuizQuestions.length - 1 ? "Finish course →" : "Next question →";
  answerList.querySelectorAll(".cyber-answer-choice").forEach((button) => {
    button.addEventListener("click", () => answerCyberQuiz(Number(button.dataset.cyberAnswer)));
  });
  nextButton.addEventListener("click", nextCyberQuizQuestion, { once: true });
}

function answerCyberQuiz(index) {
  if (state.cyberQuizAnswered) return;
  state.cyberQuizAnswered = true;
  const question = cyberQuizQuestions[state.cyberQuizIndex];
  const correct = index === question.answer;
  if (correct) state.cyberQuizScore += 1;
  cyberQuiz.querySelectorAll(".cyber-answer-choice").forEach((button) => {
    const option = Number(button.dataset.cyberAnswer);
    button.disabled = true;
    if (option === question.answer) button.classList.add("correct");
    else if (option === index) button.classList.add("incorrect");
  });
  const feedback = el("cyberQuizFeedback");
  feedback.textContent = correct ? question.explanation : `Not quite. ${question.explanation}`;
  feedback.classList.add(correct ? "good" : "bad");
  el("cyberQuizProgress").style.width = `${((state.cyberQuizIndex + 1) / cyberQuizQuestions.length) * 100}%`;
  el("cyberNextQuestion").disabled = false;
  if (correct) popSparkles(el("cyberAnswerList"));
}

function nextCyberQuizQuestion() {
  if (!state.cyberQuizAnswered) return;
  state.cyberQuizIndex += 1;
  state.cyberQuizAnswered = false;
  renderCyberQuiz();
}

function activeGameTrack() {
  return gameProjectTracks[state.gameTrack];
}

function activeGameProgress() {
  return state.gameLabProgress[state.gameTrack];
}

function activeGameProject() {
  const track = activeGameTrack();
  const progress = activeGameProgress();
  progress.current = Math.max(0, Math.min(progress.current, track.projects.length - 1));
  return track.projects[progress.current];
}

function gameProjectIsComplete(trackKey, index) {
  const track = gameProjectTracks[trackKey];
  return state.gameLabProgress[trackKey].steps[index] >= track.projects[index].steps.length;
}

function gameCompletedCount(trackKey = state.gameTrack) {
  return gameProjectTracks[trackKey].projects.filter((project, index) => gameProjectIsComplete(trackKey, index)).length;
}

function renderGameProjectMap() {
  const track = activeGameTrack();
  const progress = activeGameProgress();
  const completed = gameCompletedCount();
  gameTrackProgress.textContent = `${completed} / ${track.projects.length}`;
  gameRouteCopy.textContent = track.description;
  gameProjectMap.innerHTML = track.projects.map((project, index) => {
    const isCurrent = index === progress.current;
    const complete = gameProjectIsComplete(state.gameTrack, index);
    const locked = index > progress.current;
    const status = locked ? "locked" : complete ? "completed" : "current";
    const statusCopy = locked ? "Locked" : complete ? "Complete" : `Step ${progress.steps[index] + 1} of ${project.steps.length}`;
    return `
      <article class="game-project-card is-${status}" ${isCurrent ? 'aria-current="step"' : ""}>
        <span class="game-project-card-number">${String(index + 1).padStart(2, "0")}</span>
        <span class="game-project-card-icon" aria-hidden="true">${locked ? "🔒" : project.emoji}</span>
        <span class="game-project-card-copy"><strong>${project.title}</strong><small>${project.level}</small></span>
        <span class="game-project-card-status">${statusCopy}</span>
      </article>
    `;
  }).join("");
}

function renderGameProjectLab() {
  const track = activeGameTrack();
  const progress = activeGameProgress();
  const project = activeGameProject();
  const stepCount = project.steps.length;
  const completed = progress.steps[progress.current] >= stepCount;
  const isLastProject = progress.current === track.projects.length - 1;
  const completedTotal = gameCompletedCount();

  gameProjectMission.innerHTML = `
    <div class="game-mission-topline">
      <div>
        <p class="eyebrow muted-eyebrow">${track.label} · ${project.level}</p>
        <h3><span aria-hidden="true">${project.emoji}</span> ${project.title}</h3>
      </div>
      <span class="game-mission-counter">${String(progress.current + 1).padStart(2, "0")} / ${track.projects.length}</span>
    </div>
    <div class="game-project-brief">
      <div class="game-brief-kicker"><span aria-hidden="true">✦</span> Project brief</div>
      <p>${project.brief}</p>
      <div class="game-project-outcome"><span>Build target</span><strong>${project.outcome}</strong></div>
      <div class="game-project-skills"><span>Practice</span>${project.skills.split(" · ").map((skill) => `<b>${skill}</b>`).join("")}</div>
    </div>
    <div class="game-mission-progress" aria-label="${progress.steps[progress.current]} of ${stepCount} checkpoints completed">
      ${project.steps.map((step, index) => `<span class="game-mission-dot ${index < progress.steps[progress.current] ? "is-complete" : ""} ${index === Math.min(progress.steps[progress.current], stepCount - 1) && !completed ? "is-current" : ""}"><i aria-hidden="true">${index < progress.steps[progress.current] ? "✓" : index + 1}</i><small>${step.phase}</small></span>`).join("")}
    </div>
    ${completed ? `
      <div class="game-project-complete" aria-live="polite">
        <span aria-hidden="true">✦</span>
        <div><strong>${isLastProject ? `${track.label} complete!` : "Mission complete!"}</strong><p>${isLastProject ? `You finished all ${track.projects.length} ${track.singular}s. Your project route is fully lit.` : "You passed all three checkpoints. The next mission is ready when you are."}</p></div>
      </div>
      <div class="game-mission-actions">
        <p>${completedTotal} of ${track.projects.length} projects complete</p>
        <button id="gameNextProject" class="game-next-project" type="button" ${isLastProject ? "disabled" : ""}>${isLastProject ? "Track complete ✦" : `Unlock project ${progress.current + 2} →`}</button>
      </div>
    ` : (() => {
      const stepIndex = progress.steps[progress.current];
      const step = project.steps[stepIndex];
      return `
        <section class="game-checkpoint" aria-labelledby="gameCheckpointTitle">
          <div class="game-checkpoint-heading">
            <span>Checkpoint ${stepIndex + 1} of ${stepCount}</span>
            <span>${step.phase}</span>
          </div>
          <h4 id="gameCheckpointTitle">${step.prompt}</h4>
          <div class="game-choice-list" id="gameChoiceList">
            ${step.choices.map((choice, index) => `<button type="button" class="game-choice" data-game-choice="${index}"><span>${String.fromCharCode(65 + index)}</span>${choice}</button>`).join("")}
          </div>
          <div class="game-checkpoint-footer">
            <p id="gameCheckpointFeedback" aria-live="polite">Choose the move that would make this project clearer, kinder, or more playable.</p>
            <button id="gameContinueCheckpoint" class="game-continue-checkpoint" type="button" hidden></button>
          </div>
        </section>
      `;
    })()}
  `;

  renderGameProjectMap();
  if (completed) {
    const nextProject = el("gameNextProject");
    if (nextProject && !isLastProject) nextProject.addEventListener("click", advanceGameProject);
    return;
  }
  gameProjectMission.querySelectorAll("[data-game-choice]").forEach((button) => {
    button.addEventListener("click", () => answerGameCheckpoint(Number(button.dataset.gameChoice), button));
  });
}

function answerGameCheckpoint(choiceIndex, button) {
  if (state.gameCheckpointAnswered) return;
  state.gameCheckpointAnswered = true;
  const progress = activeGameProgress();
  const project = activeGameProject();
  const stepIndex = progress.steps[progress.current];
  const step = project.steps[stepIndex];
  const correct = choiceIndex === step.answer;
  const choices = gameProjectMission.querySelectorAll("[data-game-choice]");
  choices.forEach((choice) => {
    const option = Number(choice.dataset.gameChoice);
    choice.disabled = true;
    if (option === step.answer) choice.classList.add("correct");
    else if (option === choiceIndex) choice.classList.add("incorrect");
  });
  const feedback = el("gameCheckpointFeedback");
  const continueButton = el("gameContinueCheckpoint");
  if (correct) {
    progress.steps[progress.current] += 1;
    persistGameLabProgress();
    feedback.textContent = `Correct. ${step.explanation}`;
    feedback.className = "good";
    continueButton.textContent = stepIndex === project.steps.length - 1 ? "Finish mission →" : `Continue to checkpoint ${stepIndex + 2} →`;
    popSparkles(button);
  } else {
    feedback.textContent = `Not yet. ${step.explanation} Try this checkpoint again to continue.`;
    feedback.className = "bad";
    continueButton.textContent = "Try again";
  }
  continueButton.hidden = false;
  continueButton.addEventListener("click", () => {
    state.gameCheckpointAnswered = false;
    renderGameProjectLab();
  }, { once: true });
}

function advanceGameProject() {
  const track = activeGameTrack();
  const progress = activeGameProgress();
  if (!gameProjectIsComplete(state.gameTrack, progress.current)) {
    showToast("Pass all three checkpoints to unlock the next project.");
    return;
  }
  if (progress.current >= track.projects.length - 1) {
    showToast(`${track.label} is complete — amazing project work!`);
    return;
  }
  progress.current += 1;
  state.gameCheckpointAnswered = false;
  persistGameLabProgress();
  renderGameProjectLab();
  showToast(`Project ${progress.current + 1} unlocked. New mission, new skill!`);
}

function setGameTrack(trackKey) {
  if (!gameProjectTracks[trackKey]) return;
  state.gameTrack = trackKey;
  state.gameCheckpointAnswered = false;
  document.querySelectorAll(".game-track-tab").forEach((tab) => {
    const selected = tab.dataset.gameTrack === trackKey;
    tab.classList.toggle("is-active", selected);
    tab.setAttribute("aria-selected", String(selected));
  });
  el("gameProjectWorkspace").setAttribute("aria-labelledby", trackKey === "design" ? "designGamesTab" : "buildingGamesTab");
  renderGameProjectLab();
}

function renderChallenge() {
  const item = challengeItems[state.challengeIndex];
  el("challengeCounter").textContent = `Round ${state.challengeIndex + 1} of ${challengeItems.length}`;
  el("challengeEmoji").textContent = item.emoji;
  el("challengePrompt").textContent = item.prompt;
  el("challengeFeedback").textContent = "Trust your first instinct.";
  el("challengeFeedback").className = "";
  document.querySelectorAll(".layer-choice").forEach((button) => {
    button.disabled = false;
    button.classList.remove("correct", "incorrect");
  });
  el("nextChallenge").disabled = true;
  el("nextChallenge").textContent = state.challengeIndex === challengeItems.length - 1 ? "Replay ↻" : "Next →";
}

function answerChallenge(layer, button) {
  if (state.challengeAnswered) return;
  state.challengeAnswered = true;
  const item = challengeItems[state.challengeIndex];
  const correct = layer === item.answer;
  if (correct) {
    state.challengeScore += 1;
    el("challengeScore").textContent = state.challengeScore;
    button.classList.add("correct");
    popSparkles(button);
  } else {
    button.classList.add("incorrect");
    document.querySelector(`.layer-choice[data-layer="${item.answer}"]`).classList.add("correct");
  }
  document.querySelectorAll(".layer-choice").forEach((choice) => choice.disabled = true);
  const feedback = el("challengeFeedback");
  feedback.textContent = correct ? item.feedback : `Close! ${item.feedback}`;
  feedback.classList.add(correct ? "good" : "bad");
  el("nextChallenge").disabled = false;
}

function nextChallenge() {
  if (!state.challengeAnswered && state.challengeIndex !== challengeItems.length - 1) return;
  if (state.challengeIndex >= challengeItems.length - 1) {
    state.challengeIndex = 0;
    state.challengeScore = 0;
    el("challengeScore").textContent = "0";
  } else {
    state.challengeIndex += 1;
  }
  state.challengeAnswered = false;
  renderChallenge();
}

function renderGlossary() {
  const grid = el("glossaryGrid");
  grid.innerHTML = cards.map((card) => `
    <button class="glossary-term" type="button" data-card-id="${card.id}">
      <strong><i class="term-dot ${card.category}"></i>${card.term}</strong>
      <small>${card.categoryLabel}</small>
    </button>
  `).join("");
  grid.querySelectorAll(".glossary-term").forEach((button) => {
    button.addEventListener("click", () => {
      const target = cards.find((card) => card.id === button.dataset.cardId);
      if (!navigateToCard(target, "all")) return;
      setMode("study");
      el("learn").scrollIntoView({ behavior: "smooth", block: "start" });
    });
  });
}

function selectTopic(topic) {
  setMode("study");
  if (setFilter(topic)) el("learn").scrollIntoView({ behavior: "smooth", block: "start" });
}

function setupEvents() {
  flashcard.addEventListener("click", flipCard);
  el("flipCard").addEventListener("click", flipCard);
  el("previousCard").addEventListener("click", () => goToCard(-1));
  el("nextCard").addEventListener("click", () => goToCard(1));
  document.querySelectorAll(".filter-chip").forEach((button) => button.addEventListener("click", () => setFilter(button.dataset.filter)));
  document.querySelectorAll(".mode-button").forEach((button) => button.addEventListener("click", () => setMode(button.dataset.mode)));
  document.querySelectorAll(".confidence-button").forEach((button) => button.addEventListener("click", () => rateCard(button.dataset.confidence, button)));
  readCodeButton.addEventListener("click", toggleReadCode);
  codeInput.addEventListener("input", updateTypingState);
  codeInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      validateTyping();
    }
  });
  checkTyping.addEventListener("click", validateTyping);
  aiPromptInput.addEventListener("input", updatePromptDraft);
  checkPrompt.addEventListener("click", validateAiPrompt);
  document.querySelectorAll("[data-topic-link]").forEach((button) => button.addEventListener("click", () => selectTopic(button.dataset.topicLink)));
  document.querySelectorAll(".layer-choice").forEach((button) => button.addEventListener("click", () => answerChallenge(button.dataset.layer, button)));
  el("nextChallenge").addEventListener("click", nextChallenge);
  const gameTabs = [...document.querySelectorAll(".game-track-tab")];
  gameTabs.forEach((tab, index) => {
    tab.addEventListener("click", () => setGameTrack(tab.dataset.gameTrack));
    tab.addEventListener("keydown", (event) => {
      if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
      event.preventDefault();
      event.stopPropagation();
      let nextIndex = index;
      if (event.key === "ArrowLeft") nextIndex = (index - 1 + gameTabs.length) % gameTabs.length;
      if (event.key === "ArrowRight") nextIndex = (index + 1) % gameTabs.length;
      if (event.key === "Home") nextIndex = 0;
      if (event.key === "End") nextIndex = gameTabs.length - 1;
      gameTabs[nextIndex].focus();
      setGameTrack(gameTabs[nextIndex].dataset.gameTrack);
    });
  });
  document.querySelectorAll("[data-game-track-link]").forEach((link) => {
    link.addEventListener("click", () => setGameTrack(link.dataset.gameTrackLink));
  });

  document.addEventListener("keydown", (event) => {
    const activeElement = document.activeElement;
    if (document.querySelector("dialog[open]")) return;
    if (activeElement instanceof Element && activeElement.closest("#sprint-path")) return;
    if (state.mode !== "study") return;
    if (activeElement instanceof Element && activeElement.closest("#game-lab")) return;
    if (activeElement instanceof Element && activeElement.closest("input, textarea, select, [contenteditable='true']")) return;
    if (event.key === "ArrowRight") {
      event.preventDefault();
      goToCard(1);
      return;
    }
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      goToCard(-1);
      return;
    }
    if (activeElement instanceof Element && activeElement.closest("button, a")) return;
    if (event.code === "Space" || event.code === "Enter") {
      event.preventDefault();
      flipCard();
    }
  });

  const savedTheme = localStorage.getItem("stacksprint-theme");
  if (savedTheme === "dark") document.body.classList.add("dark-theme");
  el("themeToggle").addEventListener("click", () => {
    document.body.classList.toggle("dark-theme");
    localStorage.setItem("stacksprint-theme", document.body.classList.contains("dark-theme") ? "dark" : "light");
  });

  el("menuButton").addEventListener("click", () => el("sidebar").classList.toggle("is-open"));
  document.querySelectorAll(".side-nav a").forEach((link) => link.addEventListener("click", () => el("sidebar").classList.remove("is-open")));
}

renderProgress();
renderCard();
renderChallenge();
renderGlossary();
renderCyberVocab();
renderCyberQuiz();
renderGameProjectLab();
setupEvents();
