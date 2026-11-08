% 200 inputs and outputs, from real runs: io(N, Predicate, Inputs, Output).
io(1,least_model,["reach(X,Y) :- edge(X,Y).\nreach(X,Z) :- edge(X,Y), reach(Y,Z).",[edge(b,c),edge(b,e),edge(c,d),edge(d,a)]],[edge(b,c),edge(b,e),edge(c,d),edge(d,a),reach(b,a),reach(b,c),reach(b,d),reach(b,e),reach(c,a),reach(c,d),reach(d,a)]).
io(2,mt_random,[3,3],[0.237964627,0.544229225,0.369955167]).
io(3,clauses_of,["f(a.b, c). g(3.14)."],["f(a.b, c)","g(3.14)"]).
io(4,canon_clause,["f(_,X) :- g(X,_)"],"f(_,V0):-g(V0,_)").
io(5,split_top,["[1,2],3"],["[1,2]","3"]).
io(6,strip_spaces,[" lead"],"lead").
io(7,take,[4,[1,2,3]],[1,2,3]).
io(8,least_model,["ancestor(X,Y) :- parent(X,Y).\nancestor(X,Z) :- parent(X,Y), ancestor(Y,Z).",[parent(bob,cal)]],[ancestor(bob,cal),parent(bob,cal)]).
io(9,mt_random,[4,3],[0.23604809,0.103166034,0.396058243]).
io(10,clauses_of,["only one clause"],["only one clause"]).
io(11,canon_clause,["q(A,B,C) :- r(C,B,A)"],"q(V0,V1,V2):-r(V2,V1,V0)").
io(12,split_top,["p(q(r,s),t),u"],["p(q(r,s),t)","u"]).
io(13,strip_spaces,["trail "],"trail").
io(14,take,[5,[1,2,3,4]],[1,2,3,4]).
io(15,least_model,["flies(X) :- bird(X), \\+ penguin(X).",[bird(pingu),bird(robin),bird(tweety),penguin(opus),penguin(pingu)]],[bird(pingu),bird(robin),bird(tweety),flies(robin),flies(tweety),penguin(opus),penguin(pingu)]).
io(16,mt_random,[5,3],[0.622901695,0.741786989,0.795193566]).
io(17,clauses_of,["a(1). b(2)."],["a(1)","b(2)"]).
io(18,canon_clause,["s(X) :- \\+ t(X)"],"s(V0):-\\+t(V0)").
io(19,split_top,["\"a,b\",c"],["\"a","b\"","c"]).
io(20,strip_spaces,["no-spaces"],"no-spaces").
io(21,take,[6,[1,2,3,4,5]],[1,2,3,4,5]).
io(22,least_model,["sibling(X,Y) :- parent(P,X), parent(P,Y), X \\= Y.",[parent(dan,fay)]],[parent(dan,fay)]).
io(23,mt_random,[6,3],[0.793340084,0.821954042,0.485034628]).
io(24,clauses_of,["% comment\np(X) :- q(X).\nq(1)."],["p(X) :- q(X)","q(1)"]).
io(25,canon_clause,["p(X) :- q(X), r(X,Y)"],"p(V0):-q(V0),r(V0,V1)").
io(26,split_top,["single"],["single"]).
io(27,strip_spaces,["p(X, Y) :- q(X)"],"p(X,Y):-q(X)").
io(28,take,[0,[]],[]).
io(29,least_model,["even(X) :- zero(X).\neven(Y) :- succ2(X,Y), even(X).",[succ2(n1,n3)]],[succ2(n1,n3)]).
io(30,mt_random,[7,3],[0.323832765,0.150849174,0.650934473]).
io(31,clauses_of,["x :- y, z.\ny.\nz."],["x :- y, z","y","z"]).
io(32,canon_clause,["edge(a,b)"],"edge(a,b)").
io(33,split_top,["a,b,c"],["a","b","c"]).
io(34,strip_spaces,["  "],"").
io(35,take,[1,[1]],[1]).
io(36,least_model,["both(X) :- a(X), b(X).\neither(X) :- a(X).\neither(X) :- b(X).",[a(x)]],[a(x),either(x)]).
io(37,mt_random,[8,3],[0.226705859,0.962295036,0.126330899]).
io(38,clauses_of,[""],[]).
io(39,canon_clause,["reach(Foo,Bar) :- edge(Foo,Baz), reach(Baz,Bar)"],"reach(V0,V1):-edge(V0,V2),reach(V2,V1)").
io(40,split_top,["f(x,y),g(z)"],["f(x,y)","g(z)"]).
io(41,strip_spaces,["a b c"],"abc").
io(42,take,[2,[1,2]],[1,2]).
io(43,least_model,["reach(X,Y) :- edge(X,Y).\nreach(X,Z) :- edge(X,Y), reach(Y,Z).",[edge(b,c)]],[edge(b,c),reach(b,c)]).
io(44,mt_random,[9,3],[0.463007358,0.373311931,0.138539413]).
io(45,clauses_of,["% comment\np(X) :- q(X).\nq(1)."],["p(X) :- q(X)","q(1)"]).
io(46,canon_clause,["edge(a,b)"],"edge(a,b)").
io(47,split_top,["f(x,y),g(z)"],["f(x,y)","g(z)"]).
io(48,strip_spaces,[" lead"],"lead").
io(49,take,[3,[1,2,3,4,5]],[1,2,3]).
io(50,least_model,["ancestor(X,Y) :- parent(X,Y).\nancestor(X,Z) :- parent(X,Y), ancestor(Y,Z).",[parent(ann,bob),parent(bob,cal),parent(cal,dee)]],[ancestor(ann,bob),ancestor(ann,cal),ancestor(ann,dee),ancestor(bob,cal),ancestor(bob,dee),ancestor(cal,dee),parent(ann,bob),parent(bob,cal),parent(cal,dee)]).
io(51,mt_random,[10,3],[0.571402595,0.428889055,0.578091301]).
io(52,clauses_of,["x :- y, z.\ny.\nz."],["x :- y, z","y","z"]).
io(53,canon_clause,["reach(Foo,Bar) :- edge(Foo,Baz), reach(Baz,Bar)"],"reach(V0,V1):-edge(V0,V2),reach(V2,V1)").
io(54,split_top,["[1,2],3"],["[1,2]","3"]).
io(55,strip_spaces,["trail "],"trail").
io(56,take,[4,[]],[]).
io(57,least_model,["flies(X) :- bird(X), \\+ penguin(X).",[bird(robin)]],[bird(robin),flies(robin)]).
io(58,mt_random,[11,3],[0.452379554,0.559772386,0.924210584]).
io(59,clauses_of,[""],[]).
io(60,canon_clause,["f(_,X) :- g(X,_)"],"f(_,V0):-g(V0,_)").
io(61,split_top,["p(q(r,s),t),u"],["p(q(r,s),t)","u"]).
io(62,strip_spaces,["no-spaces"],"no-spaces").
io(63,take,[5,[1]],[1]).
io(64,least_model,["sibling(X,Y) :- parent(P,X), parent(P,Y), X \\= Y.",[parent(ann,bob),parent(ann,gus),parent(dan,fay)]],[parent(ann,bob),parent(ann,gus),parent(dan,fay),sibling(bob,gus),sibling(gus,bob)]).
io(65,mt_random,[12,3],[0.474570679,0.657472503,0.666410471]).
io(66,clauses_of,["f(a.b, c). g(3.14)."],["f(a.b, c)","g(3.14)"]).
io(67,canon_clause,["q(A,B,C) :- r(C,B,A)"],"q(V0,V1,V2):-r(V2,V1,V0)").
io(68,split_top,["\"a,b\",c"],["\"a","b\"","c"]).
io(69,strip_spaces,["p(X, Y) :- q(X)"],"p(X,Y):-q(X)").
io(70,take,[6,[1,2]],[1,2]).
io(71,least_model,["even(X) :- zero(X).\neven(Y) :- succ2(X,Y), even(X).",[succ2(n0,n2),succ2(n1,n3),succ2(n4,n6)]],[succ2(n0,n2),succ2(n1,n3),succ2(n4,n6)]).
io(72,mt_random,[13,3],[0.259008492,0.685257993,0.684081918]).
io(73,clauses_of,["only one clause"],["only one clause"]).
io(74,canon_clause,["s(X) :- \\+ t(X)"],"s(V0):-\\+t(V0)").
io(75,split_top,["single"],["single"]).
io(76,strip_spaces,["  "],"").
io(77,take,[0,[1,2,3]],[]).
io(78,least_model,["both(X) :- a(X), b(X).\neither(X) :- a(X).\neither(X) :- b(X).",[a(x),a(y),b(z)]],[a(x),a(y),b(z),either(x),either(y),either(z)]).
io(79,mt_random,[14,3],[0.106828538,0.702585524,0.65204202]).
io(80,clauses_of,["a(1). b(2)."],["a(1)","b(2)"]).
io(81,canon_clause,["p(X) :- q(X), r(X,Y)"],"p(V0):-q(V0),r(V0,V1)").
io(82,split_top,["a,b,c"],["a","b","c"]).
io(83,strip_spaces,["a b c"],"abc").
io(84,take,[1,[1,2,3,4]],[1]).
io(85,least_model,["reach(X,Y) :- edge(X,Y).\nreach(X,Z) :- edge(X,Y), reach(Y,Z).",[edge(b,e)]],[edge(b,e),reach(b,e)]).
io(86,mt_random,[15,3],[0.965242142,0.011654694,0.73599162]).
io(87,clauses_of,["f(a.b, c). g(3.14)."],["f(a.b, c)","g(3.14)"]).
io(88,canon_clause,["s(X) :- \\+ t(X)"],"s(V0):-\\+t(V0)").
io(89,split_top,["a,b,c"],["a","b","c"]).
io(90,strip_spaces,[" lead"],"lead").
io(91,take,[2,[1]],[1]).
io(92,least_model,["ancestor(X,Y) :- parent(X,Y).\nancestor(X,Z) :- parent(X,Y), ancestor(Y,Z).",[parent(ann,bob),parent(ann,eve),parent(bob,cal),parent(eve,fay)]],[ancestor(ann,bob),ancestor(ann,cal),ancestor(ann,eve),ancestor(ann,fay),ancestor(bob,cal),ancestor(eve,fay),parent(ann,bob),parent(ann,eve),parent(bob,cal),parent(eve,fay)]).
io(93,mt_random,[16,3],[0.361522775,0.480480666,0.416952627]).
io(94,clauses_of,["only one clause"],["only one clause"]).
io(95,canon_clause,["p(X) :- q(X), r(X,Y)"],"p(V0):-q(V0),r(V0,V1)").
io(96,split_top,["f(x,y),g(z)"],["f(x,y)","g(z)"]).
io(97,strip_spaces,["trail "],"trail").
io(98,take,[3,[1,2]],[1,2]).
io(99,least_model,["flies(X) :- bird(X), \\+ penguin(X).",[bird(robin),penguin(pingu)]],[bird(robin),flies(robin),penguin(pingu)]).
io(100,mt_random,[17,3],[0.52198391,0.806690777,0.960494774]).
io(101,clauses_of,["a(1). b(2)."],["a(1)","b(2)"]).
io(102,canon_clause,["edge(a,b)"],"edge(a,b)").
io(103,split_top,["[1,2],3"],["[1,2]","3"]).
io(104,strip_spaces,["no-spaces"],"no-spaces").
io(105,take,[4,[1,2,3]],[1,2,3]).
io(106,least_model,["sibling(X,Y) :- parent(P,X), parent(P,Y), X \\= Y.",[parent(dan,eve)]],[parent(dan,eve)]).
io(107,mt_random,[18,3],[0.181264863,0.661430548,0.334559703]).
io(108,clauses_of,["% comment\np(X) :- q(X).\nq(1)."],["p(X) :- q(X)","q(1)"]).
io(109,canon_clause,["reach(Foo,Bar) :- edge(Foo,Baz), reach(Baz,Bar)"],"reach(V0,V1):-edge(V0,V2),reach(V2,V1)").
io(110,split_top,["p(q(r,s),t),u"],["p(q(r,s),t)","u"]).
io(111,strip_spaces,["p(X, Y) :- q(X)"],"p(X,Y):-q(X)").
io(112,take,[5,[1,2,3,4]],[1,2,3,4]).
io(113,least_model,["even(X) :- zero(X).\neven(Y) :- succ2(X,Y), even(X).",[succ2(n2,n4)]],[succ2(n2,n4)]).
io(114,mt_random,[19,3],[0.677125827,0.784911356,0.520466157]).
io(115,clauses_of,["x :- y, z.\ny.\nz."],["x :- y, z","y","z"]).
io(116,canon_clause,["f(_,X) :- g(X,_)"],"f(_,V0):-g(V0,_)").
io(117,split_top,["\"a,b\",c"],["\"a","b\"","c"]).
io(118,strip_spaces,["  "],"").
io(119,take,[6,[1,2,3,4,5]],[1,2,3,4,5]).
io(120,least_model,["both(X) :- a(X), b(X).\neither(X) :- a(X).\neither(X) :- b(X).",[b(y)]],[b(y),either(y)]).
io(121,mt_random,[20,3],[0.905639676,0.686254157,0.766509256]).
io(122,clauses_of,[""],[]).
io(123,canon_clause,["q(A,B,C) :- r(C,B,A)"],"q(V0,V1,V2):-r(V2,V1,V0)").
io(124,split_top,["single"],["single"]).
io(125,strip_spaces,["a b c"],"abc").
io(126,take,[0,[]],[]).
io(127,least_model,["reach(X,Y) :- edge(X,Y).\nreach(X,Z) :- edge(X,Y), reach(Y,Z).",[edge(b,c),edge(d,a)]],[edge(b,c),edge(d,a),reach(b,c),reach(d,a)]).
io(128,mt_random,[21,3],[0.16494948,0.689766924,0.63499994]).
io(129,clauses_of,["% comment\np(X) :- q(X).\nq(1)."],["p(X) :- q(X)","q(1)"]).
io(130,canon_clause,["f(_,X) :- g(X,_)"],"f(_,V0):-g(V0,_)").
io(131,split_top,["single"],["single"]).
io(132,strip_spaces,[" lead"],"lead").
io(133,take,[1,[1,2,3]],[1]).
io(134,least_model,["ancestor(X,Y) :- parent(X,Y).\nancestor(X,Z) :- parent(X,Y), ancestor(Y,Z).",[parent(ann,bob),parent(ann,eve),parent(bob,cal),parent(cal,dee),parent(eve,fay)]],[ancestor(ann,bob),ancestor(ann,cal),ancestor(ann,dee),ancestor(ann,eve),ancestor(ann,fay),ancestor(bob,cal),ancestor(bob,dee),ancestor(cal,dee),ancestor(eve,fay),parent(ann,bob),parent(ann,eve),parent(bob,cal),parent(cal,dee),parent(eve,fay)]).
io(135,mt_random,[22,3],[0.95820938,0.14036859,0.023616147]).
io(136,clauses_of,["x :- y, z.\ny.\nz."],["x :- y, z","y","z"]).
io(137,canon_clause,["q(A,B,C) :- r(C,B,A)"],"q(V0,V1,V2):-r(V2,V1,V0)").
io(138,split_top,["a,b,c"],["a","b","c"]).
io(139,strip_spaces,["trail "],"trail").
io(140,take,[2,[1,2,3,4]],[1,2]).
io(141,least_model,["flies(X) :- bird(X), \\+ penguin(X).",[bird(opus),bird(pingu),bird(robin)]],[bird(opus),bird(pingu),bird(robin),flies(opus),flies(pingu),flies(robin)]).
io(142,mt_random,[23,3],[0.924865252,0.948605778,0.892433344]).
io(143,clauses_of,[""],[]).
io(144,canon_clause,["s(X) :- \\+ t(X)"],"s(V0):-\\+t(V0)").
io(145,split_top,["f(x,y),g(z)"],["f(x,y)","g(z)"]).
io(146,strip_spaces,["no-spaces"],"no-spaces").
io(147,take,[3,[1,2,3,4,5]],[1,2,3]).
io(148,least_model,["sibling(X,Y) :- parent(P,X), parent(P,Y), X \\= Y.",[parent(ann,bob),parent(ann,cal),parent(dan,eve)]],[parent(ann,bob),parent(ann,cal),parent(dan,eve),sibling(bob,cal),sibling(cal,bob)]).
io(149,mt_random,[24,3],[0.712342988,0.839799736,0.182591887]).
io(150,clauses_of,["f(a.b, c). g(3.14)."],["f(a.b, c)","g(3.14)"]).
io(151,canon_clause,["p(X) :- q(X), r(X,Y)"],"p(V0):-q(V0),r(V0,V1)").
io(152,split_top,["[1,2],3"],["[1,2]","3"]).
io(153,strip_spaces,["p(X, Y) :- q(X)"],"p(X,Y):-q(X)").
io(154,take,[4,[]],[]).
io(155,least_model,["even(X) :- zero(X).\neven(Y) :- succ2(X,Y), even(X).",[zero(n0),succ2(n1,n3),succ2(n4,n6)]],[even(n0),zero(n0),succ2(n1,n3),succ2(n4,n6)]).
io(156,mt_random,[25,3],[0.376962302,0.926788508,0.843446739]).
io(157,clauses_of,["only one clause"],["only one clause"]).
io(158,canon_clause,["edge(a,b)"],"edge(a,b)").
io(159,split_top,["p(q(r,s),t),u"],["p(q(r,s),t)","u"]).
io(160,strip_spaces,["  "],"").
io(161,take,[5,[1]],[1]).
io(162,least_model,["both(X) :- a(X), b(X).\neither(X) :- a(X).\neither(X) :- b(X).",[a(y),b(y),b(z)]],[a(y),b(y),b(z),both(y),either(y),either(z)]).
io(163,mt_random,[26,3],[0.747291266,0.202752632,0.205158654]).
io(164,clauses_of,["a(1). b(2)."],["a(1)","b(2)"]).
io(165,canon_clause,["reach(Foo,Bar) :- edge(Foo,Baz), reach(Baz,Bar)"],"reach(V0,V1):-edge(V0,V2),reach(V2,V1)").
io(166,split_top,["\"a,b\",c"],["\"a","b\"","c"]).
io(167,strip_spaces,["a b c"],"abc").
io(168,take,[6,[1,2]],[1,2]).
io(169,least_model,["reach(X,Y) :- edge(X,Y).\nreach(X,Z) :- edge(X,Y), reach(Y,Z).",[edge(b,c),edge(b,e)]],[edge(b,c),edge(b,e),reach(b,c),reach(b,e)]).
io(170,mt_random,[27,3],[0.64849722,0.701369541,0.957047003]).
io(171,clauses_of,["f(a.b, c). g(3.14)."],["f(a.b, c)","g(3.14)"]).
io(172,canon_clause,["edge(a,b)"],"edge(a,b)").
io(173,split_top,["\"a,b\",c"],["\"a","b\"","c"]).
io(174,strip_spaces,[" lead"],"lead").
io(175,take,[0,[1,2,3,4,5]],[]).
io(176,least_model,["ancestor(X,Y) :- parent(X,Y).\nancestor(X,Z) :- parent(X,Y), ancestor(Y,Z).",[parent(ann,bob)]],[ancestor(ann,bob),parent(ann,bob)]).
io(177,mt_random,[28,3],[0.11295717,0.130852167,0.59726089]).
io(178,clauses_of,["only one clause"],["only one clause"]).
io(179,canon_clause,["reach(Foo,Bar) :- edge(Foo,Baz), reach(Baz,Bar)"],"reach(V0,V1):-edge(V0,V2),reach(V2,V1)").
io(180,split_top,["single"],["single"]).
io(181,strip_spaces,["trail "],"trail").
io(182,take,[1,[]],[]).
io(183,least_model,["flies(X) :- bird(X), \\+ penguin(X).",[bird(robin),bird(tweety)]],[bird(robin),bird(tweety),flies(robin),flies(tweety)]).
io(184,mt_random,[29,3],[0.548119054,0.345831823,0.844851089]).
io(185,clauses_of,["a(1). b(2)."],["a(1)","b(2)"]).
io(186,canon_clause,["f(_,X) :- g(X,_)"],"f(_,V0):-g(V0,_)").
io(187,split_top,["a,b,c"],["a","b","c"]).
io(188,strip_spaces,["no-spaces"],"no-spaces").
io(189,take,[2,[1]],[1]).
io(190,least_model,["sibling(X,Y) :- parent(P,X), parent(P,Y), X \\= Y.",[parent(dan,eve)]],[parent(dan,eve)]).
io(191,mt_random,[30,3],[0.539081565,0.289196444,0.030036909]).
io(192,clauses_of,["% comment\np(X) :- q(X).\nq(1)."],["p(X) :- q(X)","q(1)"]).
io(193,canon_clause,["q(A,B,C) :- r(C,B,A)"],"q(V0,V1,V2):-r(V2,V1,V0)").
io(194,split_top,["f(x,y),g(z)"],["f(x,y)","g(z)"]).
io(195,strip_spaces,["p(X, Y) :- q(X)"],"p(X,Y):-q(X)").
io(196,take,[3,[1,2]],[1,2]).
io(197,least_model,["even(X) :- zero(X).\neven(Y) :- succ2(X,Y), even(X).",[succ2(n4,n6)]],[succ2(n4,n6)]).
io(198,mt_random,[31,3],[0.012278247,0.112398861,0.392837362]).
io(199,clauses_of,["x :- y, z.\ny.\nz."],["x :- y, z","y","z"]).
io(200,canon_clause,["s(X) :- \\+ t(X)"],"s(V0):-\\+t(V0)").
