\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{uptacthesis}[2022/02/06 Report based class for UPT thesis]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{report}}
\ProcessOptions\relax
\LoadClass[12pt, a4paper]{report}

\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage{fancyhdr}
\RequirePackage{geometry}
\RequirePackage[indentafter]{titlesec}
\RequirePackage{setspace}
\RequirePackage{fontspec}
\RequirePackage{graphicx}
\RequirePackage{listings}
\RequirePackage{xcolor}
\RequirePackage[hidelinks]{hyperref}

\geometry{
    a4paper,
    total={170mm, 252mm},
    left=20mm,
    top=25mm,
    headsep=4mm,
    headheight=18mm
}

\renewcommand{\headrulewidth}{0pt}
\fancypagestyle{fancytitlepage}[fancy]{
    \fancyhf{}
    \rhead{\hspace*{-2cm}\includegraphics{assets/logo_upt.jpg}}
    \lhead{\scriptsize{Ingineria sistemelor\\\textbf{2022}}}
}
\fancypagestyle{plain}[fancy]{ 
    \fancyhf{}
    \rhead{\hspace*{-2cm}\includegraphics{logo_upt.jpg}}
    \lhead{\scriptsize{Universitatea Politehnica Timișoara\\
    Ingineria sistemelor 2022\\
    Daniel-Bogdan Horț\\
    \@title}}
    \cfoot{$ - \thepage - $}
}

\renewcommand{\maketitle}{\setlength{\parindent}{0pt}
    \thispagestyle{fancytitlepage}
    \null\vfill\begin{center}
       {\LARGE\bfseries\MakeUppercase{\@title}}
    \end{center}
    \vfill
    \begin{flushleft} \@author \end{flushleft}
    \begin{center} \@date \end{center}

    \setlength{\parindent}{1.5cm}
}

\definecolor{codegreen}{rgb}{0,0.6,0}
\definecolor{codegray}{rgb}{0.5,0.5,0.5}
\definecolor{codepurple}{rgb}{0.58,0,0.82}
\definecolor{backcolour}{rgb}{0.95,0.95,0.92}

\lstdefinestyle{mystyle}{
    backgroundcolor=\color{backcolour},   
    commentstyle=\color{codegreen},
    keywordstyle=\color{magenta},
    numberstyle=\tiny\color{codegray},
    stringstyle=\color{codepurple},
    basicstyle=\ttfamily\footnotesize,
    breakatwhitespace=false,         
    breaklines=true,                 
    captionpos=b,                    
    keepspaces=true,                 
    numbers=left,                    
    numbersep=5pt,                  
    showspaces=false,                
    showstringspaces=false,
    showtabs=false,                  
    tabsize=2
}

\lstset{style=mystyle}

\pagestyle{plain}
\setmainfont{Arial}

\titleformat{\chapter}
{\normalfont\large\bfseries\centering\uppercase}{\thechapter.}{1em}{}
\titlespacing{\chapter}{0pt}{0pt}{24pt}

\titleformat{\section}
{\normalfont\normalsize\bfseries\uppercase}{\thesection}{1em}{}
\titlespacing{\section}{0pt}{0pt}{12pt}

\titleformat{\subsection}
{\normalfont\normalsize\bfseries}{\thesubsection}{1em}{}

\setstretch{1.15}