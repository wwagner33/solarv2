function minimize() {
    //Removendo esmaecimento
    $("#dimmed_div").fadeOut('fast', function() { $("#dimmed_div").remove(); });

    //Ocultando o frame da aula
    $("#lesson_content").fadeTo('fast', 0.0, function() { $("#lesson_content").css('display', 'none'); });

    //Exibindo a abinha minimizada
    min_tab = '<div onclick="javascript:maximize();" id="min_tab" name="min_tab"><div id="close_tab_button" >&nbsp;</div>&nbsp;&nbsp; <b>Aula</b></div>';

    $("#min_button").remove();
    $("#close_button").remove();

    $("#lesson_external_div").append(min_tab);
    $("#min_tab").slideDown('fast');

    $("#close_tab_button").click(function(event) {
        close_lesson();
        event.stopPropagation();
    });
}

function maximize() {
    //Esmaecendo a tela
    dimmed_div = '<div onclick="javascript:minimize();" id="dimmed_div" name="dimmed_div" style="">&nbsp;</div>';
    $("#lesson_external_div").append(dimmed_div);
    $("#dimmed_div").fadeTo('fast', 0.8);

    //Exibindo a aula
    $("#lesson_content").fadeTo('fast', 1.0);

    //Botões de minimizar e fechar
    minButton = '<div onclick="javascript:minimize();" id="min_button">&nbsp;</div>';
    closeButton = '<div onclick="javascript:close_lesson();" id="close_button">&nbsp;</div>';

    $("#lesson_external_div").append(closeButton);
    $("#lesson_external_div").append(minButton);

    //Removendo a aba minimizada
    $("#min_tab").slideUp('fast', function() { $("#min_tab").remove(); });
}

function show_lesson(caminho) {
    //Esmaecendo a tela
    dimmed_div = '<div onclick="javascript:minimize();" id="dimmed_div" name="dimmed_div">&nbsp;</div>';
    $("#lesson_external_div", parent.document.body).append(dimmed_div);
    $("#dimmed_div", parent.document.body).fadeTo('fast', 0.8);


    /* TESTANDO - inicio */
    $("#lesson_content", parent.document.body).remove();
    lessonh = '<div id=lesson_content style="">'+"<%= escape_javascript(render '/lessons/show') %>"+'</div>';
    $("#lesson_external_div", parent.document.body).append(lessonh);
    /* TESTANDO - fim    */


    //lesson = '<iframe id="lesson_content" src="' + caminho + '"></iframe>';
    lesson = '<iframe id="lessonf" src="' + caminho + '"></iframe>';

    //Exibindo a aula
    //$("#lesson_content", parent.document.body).remove();
    //$("#lesson_external_div", parent.document.body).append(lesson);
    $("#lessonf", parent.document.body).remove();
    $("#lesson_content", parent.document.body).append(lesson);
    
    setTimeout('$("#lesson_content",parent.document.body).slideDown("fast");', 500);

    //Exibindo botoes de minimizar e fechar
    minButton = '<div onclick="javascript:minimize();" id="min_button">&nbsp;</div>';
    closeButton = '<div onclick="javascript:close_lesson();" id="close_button">&nbsp;</div>';
    $("#lesson_external_div", parent.document.body).append(closeButton);
    $("#lesson_external_div", parent.document.body).append(minButton);

    //Removendo a aba minimizada, se ela estiver aparecendo
    $("#min_tab", parent.document.body).slideUp('fast', function() {$("#min_tab", parent.document.body).remove();});
}

function close_lesson() {
    //Removendo esmaecimento
    $("#dimmed_div").fadeOut('fast', function() {$("#dimmed_div").remove();});

    //Ocultando o frame da aula
    $("#lesson_content").fadeTo('fast', 0.0, function() {$("#lesson_content").remove();});

    $("#min_button").remove();
    $("#close_button").remove();

    $("#lesson_external_div").append(min_tab);
    $("#min_tab").slideDown('fast');

    //Removendo a aba minimizada, se ela estiver aparecendo
    $("#min_tab").slideUp('fast', function() {$("#min_tab").remove();});
}

function clear_lesson() {
    $("#min_tab", parent.document.body).remove();
    $("#lesson_content", parent.document.body).remove();
    $("#dimmed_div", parent.document.body).remove();
    $("#min_button", parent.document.body).remove();
    $("#close_button", parent.document.body).remove();
}
