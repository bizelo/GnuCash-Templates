; Sleek Modern Invoice stylesheet (CSS-only) for GnuCash
; Debug build: prints the raw Accent Color option value and the computed hex color.
; Install as config-user.scm, restart, then open Style Sheet Options and re-render an invoice.
; Look for lines starting with "DEBUG accent".

(define (log s) (display s) (newline) (force-output))

(log "========================================")
(log "Loading Sleek Modern Invoice stylesheet...")

(catch #t
  (lambda ()
    (use-modules (gnucash report))
    (use-modules (gnucash html))
    (use-modules (srfi srfi-13))
    (log "✓ gnucash modules loaded")

    (define (read-file->string path)
      (call-with-input-file path
        (lambda (port)
          (let loop ((chars '()))
            (let ((c (read-char port)))
              (if (eof-object? c)
                  (list->string (reverse chars))
                  (loop (cons c chars))))))))

    (define (home-dir) (or (getenv "HOME") ""))
    (define css-path (string-append (home-dir) "/Library/Application Support/Gnucash/sleek-modern-invoice.css"))

    (define css-text
      (if (file-exists? css-path)
          (begin (log (string-append "✓ CSS file found: " css-path))
                 (read-file->string css-path))
          (begin (log (string-append "✗ CSS file not found: " css-path))
                 "")))

    ;; ---- helpers
    (define (clamp255 x) (max 0 (min 255 x)))
    (define (byte->hex2 b)
      (let* ((hex "0123456789abcdef")
             (hi (quotient b 16))
             (lo (modulo b 16)))
        (string (string-ref hex hi) (string-ref hex lo))))
    (define (rgb->hex r g b)
      (string-append "#" (byte->hex2 r) (byte->hex2 g) (byte->hex2 b)))

    ;; Try multiple converter procedures if present.
    (define (try-color-converters v)
      (let ((cands (list 'gnc:color-option->html
                         'gnc:color->html
                         'gnc:color-to-html
                         'gnc:color->string)))
        (let loop ((xs cands))
          (if (null? xs)
              #f
              (let* ((sym (car xs))
                     (proc (and (defined? sym) (module-ref (current-module) sym #f))))
                (if (procedure? proc)
                    (catch #t
                      (lambda () (proc v))
                      (lambda (k . a) (loop (cdr xs))))
                    (loop (cdr xs))))))))

    ;; Fallback decoding: accept "#rrggbb", (r g b) 0..65535, or #(r g b) 0..65535
    (define (fallback-color->hex v)
      (cond
        ((and (string? v) (>= (string-length v) 7) (char=? (string-ref v 0) #\#))
         (string-downcase (string-trim-both v)))
        ((and (pair? v) (pair? (cdr v)) (pair? (cddr v)))
         (let* ((r16 (car v)) (g16 (cadr v)) (b16 (caddr v))
                (r (clamp255 (inexact->exact (round (/ r16 257.0)))))
                (g (clamp255 (inexact->exact (round (/ g16 257.0)))))
                (b (clamp255 (inexact->exact (round (/ b16 257.0))))))
           (rgb->hex r g b)))
        ((and (vector? v) (>= (vector-length v) 3))
         (let* ((r16 (vector-ref v 0))
                (g16 (vector-ref v 1))
                (b16 (vector-ref v 2))
                (r (clamp255 (inexact->exact (round (/ r16 257.0)))))
                (g (clamp255 (inexact->exact (round (/ g16 257.0)))))
                (b (clamp255 (inexact->exact (round (/ b16 257.0))))))
           (rgb->hex r g b)))
        (else "#f4d24d")))

    (define (color->hex v)
      (let ((via (try-color-converters v)))
        (cond
          ((and (string? via) (>= (string-length via) 7) (char=? (string-ref via 0) #\#)) via)
          ((string? via) via)
          (else (fallback-color->hex v)))))

    ;; Minimal blends used by your CSS
    (define (hex->byte2 s i)
      (let* ((c1 (string-ref s i))
             (c2 (string-ref s (+ i 1)))
             (d (lambda (c)
                  (cond
                    ((and (char>=? c #\0) (char<=? c #\9)) (- (char->integer c) (char->integer #\0)))
                    ((and (char>=? c #\a) (char<=? c #\f)) (+ 10 (- (char->integer c) (char->integer #\a))))
                    ((and (char>=? c #\A) (char<=? c #\F)) (+ 10 (- (char->integer c) (char->integer #\A))))
                    (else 0)))))
        (+ (* 16 (d c1)) (d c2))))
    (define (hex->rgb h)
      (let* ((t (if (and (string? h) (>= (string-length h) 7)) h "#000000"))
             (r (hex->byte2 t 1)) (g (hex->byte2 t 3)) (b (hex->byte2 t 5)))
        (list r g b)))
    (define (blend-to-white hex pct)
      (let* ((rgb (hex->rgb hex))
             (r (car rgb)) (g (cadr rgb)) (b (caddr rgb))
             (p (/ (max 0 (min 100 pct)) 100.0))
             (br (clamp255 (inexact->exact (round (+ (* r (- 1 p)) (* 255 p))))))
             (bg (clamp255 (inexact->exact (round (+ (* g (- 1 p)) (* 255 p))))))
             (bb (clamp255 (inexact->exact (round (+ (* b (- 1 p)) (* 255 p)))))))
        (rgb->hex br bg bb)))
    (define (rgba-from-hex hex alpha)
      (let* ((rgb (hex->rgb hex))
             (r (car rgb)) (g (cadr rgb)) (b (caddr rgb)))
        (string-append "rgba(" (number->string r) "," (number->string g) "," (number->string b) "," (number->string alpha) ")")))

    ;; Options
    (define (sleek-options)
      (let ((options (gnc-new-optiondb)))
        (gnc-register-text-option options (N_ "General") (N_ "CSS") "a"
          (N_ "CSS code. This field specifies the CSS code for styling reports.") css-text)

        ;; Color picker (since you said it shows up)
        (gnc-register-color-option options (N_ "Brand") (N_ "Accent Color") "a"
          (N_ "Pick an accent color for the theme.") "#f4d24d")

        (gnc-register-pixmap-option options (N_ "Brand") (N_ "Logo Image") "b"
          (N_ "Choose a logo/icon image file to use on invoices (PNG/SVG recommended).") "")
        options))

    ;; Renderer
    (define (sleek-renderer options doc)
      (let* ((ssdoc (gnc:make-html-document))
             (css (gnc-optiondb-lookup-value options "General" "CSS"))
             (report-css (or (gnc:html-document-style-text doc) ""))
             (all-css (string-append css report-css))
             (accent-val (gnc-optiondb-lookup-value options "Brand" "Accent Color"))
             (logo-path  (gnc-optiondb-lookup-value options "Brand" "Logo Image"))
             (accent-hex (color->hex accent-val))

             (logo-url (if (and (string? logo-path) (not (equal? logo-path "")))
                           (string-append "url('file://" logo-path "')")
                           "none"))

             (brand-vars
               (string-append
                 ":root{"
                 "--sb-accent:" accent-hex ";"
                 "--sb-logo-url:" logo-url ";"
                 "--sb-accent-85w:" (blend-to-white accent-hex 35) ";"
                 "--sb-accent-55w:" (blend-to-white accent-hex 55) ";"
                 "--sb-accent-25w:" (blend-to-white accent-hex 75) ";"
                 "--sb-accent-45w:" (blend-to-white accent-hex 55) ";"
                 "--sb-accent-12w:" (blend-to-white accent-hex 88) ";"
                 "--sb-accent-35w:" (blend-to-white accent-hex 65) ";"
                 "--sb-accent-rgba35:" (rgba-from-hex accent-hex 0.35) ";"
                 "--sb-accent-rgba28:" (rgba-from-hex accent-hex 0.28) ";"
                 "}\n")))

        (log "DEBUG accent raw value:")
        (write accent-val) (newline) (force-output)
        (log (string-append "DEBUG accent hex: " accent-hex))

        (set! all-css (string-append brand-vars all-css))

        ;; Map semantic names to classes used by reports
        (gnc:html-document-set-style! ssdoc "column-heading-left"   'tag "th" 'attribute (list "class" "column-heading-left"))
        (gnc:html-document-set-style! ssdoc "column-heading-center" 'tag "th" 'attribute (list "class" "column-heading-center"))
        (gnc:html-document-set-style! ssdoc "column-heading-right"  'tag "th" 'attribute (list "class" "column-heading-right"))
        (gnc:html-document-set-style! ssdoc "date-cell"             'tag "td" 'attribute (list "class" "date-cell"))
        (gnc:html-document-set-style! ssdoc "anchor-cell"           'tag "td" 'attribute (list "class" "anchor-cell"))
        (gnc:html-document-set-style! ssdoc "number-cell"           'tag "td" 'attribute (list "class" "number-cell"))
        (gnc:html-document-set-style! ssdoc "number-cell-neg"       'tag "td" 'attribute (list "class" "number-cell neg"))
        (gnc:html-document-set-style! ssdoc "number-header"         'tag "th" 'attribute (list "class" "number-header"))
        (gnc:html-document-set-style! ssdoc "text-cell"             'tag "td" 'attribute (list "class" "text-cell"))
        (gnc:html-document-set-style! ssdoc "total-number-cell"     'tag "td" 'attribute (list "class" "total-number-cell"))
        (gnc:html-document-set-style! ssdoc "total-number-cell-neg" 'tag "td" 'attribute (list "class" "total-number-cell neg"))
        (gnc:html-document-set-style! ssdoc "total-label-cell"      'tag "td" 'attribute (list "class" "total-label-cell"))
        (gnc:html-document-set-style! ssdoc "centered-label-cell"   'tag "td" 'attribute (list "class" "centered-label-cell"))
        (gnc:html-document-set-style! ssdoc "normal-row"            'tag "tr")
        (gnc:html-document-set-style! ssdoc "alternate-row"         'tag "tr")
        (gnc:html-document-set-style! ssdoc "primary-subheading"    'tag "tr")
        (gnc:html-document-set-style! ssdoc "secondary-subheading"  'tag "tr")
        (gnc:html-document-set-style! ssdoc "grand-total"           'tag "tr")

        (if (string-contains-ci all-css "</style")
            (begin
              (gnc:html-document-set-style-text! ssdoc "/* </style is disallowed in CSS. */")
              (gnc:html-document-add-object! ssdoc (gnc:make-html-text (G_ "&lt;/style is disallowed in CSS. Not loading provided CSS."))))
            (gnc:html-document-set-style-text! ssdoc all-css))

        (gnc:html-document-append-objects! ssdoc (gnc:html-document-objects doc))
        ssdoc))

    (gnc:define-html-style-sheet
      'version 1
      'name (N_ "Sleek Modern Invoice")
      'renderer sleek-renderer
      'options-generator sleek-options)

    (gnc:make-html-style-sheet "Sleek Modern Invoice" (N_ "Sleek Modern Invoice"))
    (log "✓✓✓ SUCCESS! Sleek Modern Invoice stylesheet created."))
  (lambda (key . args)
    (log "✗ ERROR while loading Sleek Modern Invoice stylesheet:")
    (log (string-append "  Key: " (if (symbol? key) (symbol->string key) (format #f "~a" key))))
    (log "  Args:")
    (write args) (newline) (force-output)))

(log "========================================")
