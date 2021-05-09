(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))


(require 'use-package)
(setq use-package-always-ensure t)

(defvar barremacs/default-font-size 132)
(defvar barremacs/var-pitch-font-size 160)

(setq inhibit-startup-message t)

(scroll-bar-mode -1)        ; Disable visible scrollbar
(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 10)        ; Give some breathing room

(menu-bar-mode -1)            ; Disable the menu bar

;; Set up the visible bell
(setq visible-bell t)

(column-number-mode)
(global-display-line-numbers-mode t)

(defun barremacs/set-font-faces ()
  (message "setting faces")
  (set-face-attribute 'default nil :font "Fira Code" :height barremacs/default-font-size))

;;Sets the fonts correctly if running emacs in daemon mode.
(if (daemonp)
    (add-hook 'after-make-frame-functions
	      (lambda (frame)
		(setq doom-modeline-icon t)
		(with-selected-frame frame
		  (barremacs/set-font-faces))))
  (barremacs/set-font-faces))

(use-package magit)

(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))

(defun barremacs/org-babel-tangle-config ()
  (when (string-equal (file-name-directory (buffer-file-name))
		      (expand-file-name "~/.emacs.d/"))

    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))


(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'barremacs/org-babel-tangle-config)))

(setq mode-line-format
      (list "-"
	    'mode-line-mule-info
	    'mode-line-modified
	    'mode-line-frame-identification
	    "%b  "

	    ;; Note that this is evaluated while making the list.
	    ;; It makes a mode line construct which is just a string.
	    (getenv "HOST")



	    ;;":"
	    'default-directory
	    "   "
	    ;;'global-mode-string
	    ;;"   %[("
	    ;;'(:eval (format-time-string "%F"))
	    'mode-line-process
	    'minor-mode-alist
	    ;;"%n"
	    ;;")%]--"

	    '(which-function-mode ("" which-func-format "--"))
	    '(line-number-mode "%l:")
	    '(column-number-mode "%c ")


	    ;;'(-3 "%p")
	    ))

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
	 :map ivy-minibuffer-map
	 ("TAB" . ivy-alt-done)
	 ("C-l" . ivy-alt-done)
	 ("C-j" . ivy-next-line)
	 ("C-k" . ivy-previous-line)
	 :map ivy-switch-buffer-map
	 ("C-k" . ivy-previous-line)
	 ("C-l" . ivy-done)
	 ("C-d" . ivy-switch-buffer-kill)
	 :map ivy-reverse-i-search-map
	 ("C-k" . ivy-previous-line)
	 ("C-d" . ivy-reverse-i-search-kill))
  :config
  (ivy-mode 1))


(use-package ivy-rich
  :init
  (ivy-rich-mode 1))

(use-package counsel
  :bind (("M-x" . counsel-M-x)
	 ("C-x b" . counsel-ibuffer)
	 ("C-x C-f" . counsel-find-file)
	 :map minibuffer-local-map
	 ("C-r" . 'counsel-minibuffer-history))
  :custom
  (counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))

(use-package general
  :config
  (general-create-definer barremacs/leader-keys
    :prefix "C-c"
    :global-prefix "C-c"))

(general-define-key
 "C-M-j" 'counsel-switch-buffer
 "C-M-," 'magit-status
 "C-M-k" 'kill-buffer-and-window
 "C-c a" 'org-agenda)

(barremacs/leader-keys
  "c" '(:ignore c :which-key "code")
  "cc" '(comment-org-uncomment-region :which-key "comment"))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package yasnippet)
(use-package yasnippet-snippets)
(yas-global-mode 1)

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  ;; NOTE: Set this to the folder where you keep your Git repos!
  (when (file-directory-p "~/Development/")
    (setq projectile-project-search-path '("~/Development/")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

(defun barremacs/lsp-mode-setup ()
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbolds))
  (lsp-headerline-breadcrumb-mode))

(use-package lsp-mode 
  :commands (lsp lsp-deferred)
  :hook (prog-mode . lsp-mode)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (lsp-enable-which-key-integration t)
  ;;   (lsp-enable-snippet t)
  )

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-position 'bottom))

(use-package lsp-treemacs
  :after lsp)

(use-package company
  :after lsp-mode
  :hook (lsp-mode . company-mode)
  (lsp-mode . yas-minor-mode)

  :custom
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.0))

;;(require 'company-lsp)
;;(push 'company-lsp company-backends)

(with-eval-after-load 'company 

  (define-key company-active-map (kbd "<tab>") 'company-complete-selection)
  (define-key company-active-map (kbd "TAB") 'company-complete-selection))

(use-package csharp-mode
  :mode "\\.cs\\'"
  :hook (csharp-mode . lsp-deferred))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(tango-dark)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )